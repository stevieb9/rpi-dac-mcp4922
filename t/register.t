use warnings;
use strict;

use Test::More;

use RPi::DAC::MCP4922;

my $mod = 'RPi::DAC::MCP4922';

# All HW-free: the pure XS word-builders (_reg_init/__set_dac/__build_word)
# return the assembled register word, and every accessor/constructor validation
# dies before any wiringPi call - so nothing here touches a Pi or the SPI bus.
# __build_word() is the word assembly split out of _set() (B19) so the 12-bit
# field-clear (the B9 mask fix) is unit-testable without an 8/10-bit part.

# --- _reg_init(buf, gain): BUF(14) | GAIN(13) | SHDN(12, always on) ---

is RPi::DAC::MCP4922::_reg_init(0, 0), 0x1000, "_reg_init(0,0): SHDN only";
is RPi::DAC::MCP4922::_reg_init(0, 1), 0x3000, "_reg_init(0,1): GAIN + SHDN";
is RPi::DAC::MCP4922::_reg_init(1, 0), 0x5000, "_reg_init(1,0): BUF + SHDN";
is RPi::DAC::MCP4922::_reg_init(1, 1), 0x7000, "_reg_init(1,1): BUF + GAIN + SHDN";

# --- __set_dac(buf, dac): sets/clears DAC-select bit 15, preserves the rest ---

is RPi::DAC::MCP4922::__set_dac(0x0000, 0), 0x0000, "__set_dac: DAC A leaves bit 15 clear";
is RPi::DAC::MCP4922::__set_dac(0x0000, 1), 0x8000, "__set_dac: DAC B sets bit 15";
is RPi::DAC::MCP4922::__set_dac(0x7000, 1), 0xF000, "__set_dac: DAC B preserves the control bits";
is RPi::DAC::MCP4922::__set_dac(0x8000, 0), 0x0000, "__set_dac: DAC A clears bit 15";

# --- __build_word(buf, dac, lsb, data): the pure word assembly split out of
#     _set() (B19). Sets the DAC-select bit, clears the ENTIRE 12-bit data
#     field, then ORs in data << lsb. This is where the B9 mask bug lived:
#     without an 8/10-bit MCP4902/4912 on the bench, these cases exercise it. ---

my $bw = \&RPi::DAC::MCP4922::__build_word;

# DAC-select bit + control-nibble preservation
is $bw->(0x7000, 0, 0, 0xABC), 0x7ABC, "__build_word: DAC A preserves control nibble";
is $bw->(0x7000, 1, 0, 0xABC), 0xFABC, "__build_word: DAC B sets bit 15, keeps control bits";

# 12-bit part (lsb 0): data written straight into the field
is $bw->(0x7000, 0, 0, 0xFFF), 0x7FFF, "12-bit: full-scale data";
is $bw->(0x7FFF, 0, 0, 0x000), 0x7000, "12-bit: stale full field cleared to zero";

# 10-bit part (lsb 2): data left-aligned into bits 11-2
is $bw->(0x7000, 0, 2, 1023), 0x7FFC, "10-bit: full-scale (1023 << 2)";
is $bw->(0x7000, 0, 2, 512),  0x7800, "10-bit: mid-scale (512 << 2)";
# B9 REGRESSION GUARD: a stale cached word must have its WHOLE field cleared.
# The old mask (0xFFF >> 2 = 0x3FF) left bits 11-10 set -> 0x7C00, not 0x7000.
is $bw->(0x7FFF, 0, 2, 0), 0x7000, "10-bit: stale top-of-field bits cleared (B9)";

# 8-bit part (lsb 4): data left-aligned into bits 11-4
is $bw->(0x7000, 0, 4, 255), 0x7FF0, "8-bit: full-scale (255 << 4)";
is $bw->(0x7ABC, 0, 4, 0x0A), 0x70A0, "8-bit: stale field replaced (0x0A << 4)";
# B9 REGRESSION GUARD: old mask (0xFFF >> 4 = 0xFF) left bits 11-8 set -> 0x7F00.
is $bw->(0x7FFF, 0, 4, 0), 0x7000, "8-bit: stale top-of-field bits cleared (B9)";

# --- model -> bits -> lsb chain ---

my %model_bits = (MCP4922 => 12, MCP4912 => 10, MCP4902 => 8, 4922 => 12);
for my $model (sort keys %model_bits) {
    my $d = bless {}, $mod;
    is $d->_model($model), $model_bits{$model}, "_model('$model') -> $model_bits{$model} bits";
}

for my $pair ([12, 0], [10, 2], [8, 4]) {
    my ($bits, $lsb) = @$pair;
    my $d = bless { model => $bits }, $mod;
    is $d->_lsb,      $lsb, "_lsb for $bits-bit model = $lsb";
    is $d->_data_lsb, $lsb, "_data_lsb for $bits-bit model = $lsb";
}

{
    my $d = bless {}, $mod;
    eval { $d->_model('MCP4999') };
    like $@, qr/invalid model/, "_model() dies on a known-format but unmapped model";

    $d = bless {}, $mod;
    eval { $d->_model };
    like $@, qr/no model specified/, "_model() dies when no model is set";
}

# --- accessor validation (dies before any hardware) ---

my %bad = (
    _buf      => [2, -1],
    _channel  => [2, -1],
    _gain     => [2, -1],
    _cs       => [64, -1],
    _shdn_pin => [64, -1],
);
for my $acc (sort keys %bad) {
    for my $val (@{ $bad{$acc} }) {
        my $d = bless {}, $mod;
        eval { $d->$acc($val) };
        ok $@, "$acc($val) dies (out of range)";
    }
}

{
    my $d = bless {}, $mod;
    is $d->_buf,  0, "_buf defaults to 0";
    is $d->_gain, 1, "_gain defaults to 1";
}

# --- register() accessor: set / get / default ---

{
    my $d = bless {}, $mod;
    is $d->register, 0, "register() defaults to 0";
    is $d->register(0x3000), 0x3000, "register() sets and returns the value";
    is $d->register, 0x3000, "register() persists the value";
}

# --- enable/disable guards (die before any SPI write) ---

{
    my $d = bless {}, $mod;
    eval { $d->disable_sw }; like $@, qr/no DAC specified/, "disable_sw() requires a DAC";
    eval { $d->enable_sw };  like $@, qr/no DAC specified/, "enable_sw() requires a DAC";
    eval { $d->disable_hw }; like $@, qr/SHDN pin/,         "disable_hw() requires a SHDN pin";
    eval { $d->enable_hw };  like $@, qr/SHDN pin/,         "enable_hw() requires a SHDN pin";
}

# --- new() validates args before touching hardware ---

eval { $mod->new(channel => 0, cs => 18) };
like $@, qr/no model specified/, "new() without a model dies before hardware";

eval { $mod->new(model => 'MCP4999', channel => 0, cs => 18) };
like $@, qr/invalid model/, "new() with an unmapped model dies before hardware";

eval { $mod->new(model => 'MCP4922', channel => 0, cs => 18, buf => 2) };
like $@, qr/buf must be/, "new() with a bad buf dies before hardware";

done_testing();
