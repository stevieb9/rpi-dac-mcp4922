use warnings;
use strict;
use feature 'say';

use Bit::Manip qw(:all);
use RPi::WiringPi;
use RPi::WiringPi::Constant qw(:all);

my $spi_chan = 0;

my $pi = RPi::WiringPi->new;

my $adc = $pi->adc;
my $spi = $pi->spi($spi_chan);

my $cs_pin = $pi->pin(18);
my $shdn_pin = $pi->pin(6);

# light up some pins per the datasheet

# device channel select (CS) to HIGH, in case the
# device started it as LOW. In this case, we
# bit-bang the CS pin, instead of using the 
# hardware one

$cs_pin->mode(OUTPUT);
$cs_pin->write(HIGH);

# device 'shutdown' (SHDN) pin we'll tie to HIGH
# as we're not devising API strategy for it yet.
# when tied to HIGH, means all channels active(

$shdn_pin->mode(OUTPUT);
$shdn_pin->write(HIGH);

# show the current voltage output % on both DAC
# channels before we begin

say $adc->percent(0);
say $adc->percent(1);


sub dac_write {
    my ($dac) = @_;

    # init the register

    my $register = [0, 0];

    # (bit 7) set the onboard DAC (a/b == 0/1) we're writing to

    $register->[0] = bit_on($register->[0], 7);
    say "dac: " . bit_bin($register->[0]);

    # (bit 6) we're not into the meat of the IC yet, so we're not
    # buffering

    $register->[0] = bit_set($register->[0], 6, 1, 0); 
    say "buf: " . bit_bin($register->[0]);

# GAIN
    $register->[0] = bit_on($register->[0], 5); 
    say "shdn: " . bit_bin($register->[0]);

# SHDN
    $register->[0] = bit_set($register->[0], 4, 1, 1); 
    say "ga: " . bit_bin($register->[0]);

# DATA
    $register->[0] = bit_set($register->[0], 0, 4, 0b1111);
    say "d byte1: " . bit_bin($register->[0]);

# DATA byte 2
    $register->[1] = bit_set($register->[1], 0, 8, 255);
    say "d byte2: " . bit_bin($register->[1]);

# drop chip select to LOW to start conversation with the DAC

    $cs_pin->write(LOW);
    say $cs_pin->read;

# write our bytes to the SPI bus

    $spi->rw($register, 2);

# go HIGH to tell the IC we're done clocking in bits

    $cs_pin->write(HIGH);

# sleep 1;

# validate the analog out with our ADC

    say $adc->volts(0);
    say $adc->volts(1);

    $pi->cleanup;
