package RPi::DAC::MCP4922;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('RPi::DAC::MCP4922', $VERSION);

my $model_map = {
    4902    => 8,
    4912    => 10,
    4922    => 12,
};

# public methods

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $self->_buf($args{buf});
    $self->_channel($args{channel});
    $self->_cs($args{cs});
    $self->_gain($args{gain});
    $self->_model($args{model});
    $self->_shdn_pin($args{shdn});

    $self->_init($self->_buf, $self->_gain);
}
sub disable_hard {
    my ($self) = shift;
    die "no SHDN pin has been spedified\n" if ! defined $self->_shdn_pin;
    $self->_disable_hard($self->_channel, $self->_cs, $self->_shdn_pin);
}
sub disable_soft {
    my ($self, $dac) = @_;
    die "no DAC specified\n" if ! defined $dac;
    $self->_disable_soft($self->_channel, $self->_cs, $dac);
}
sub enable_hard {
    my ($self) = shift;
    die "no SHDN pin has been spedified\n" if ! defined $self->_shdn_pin;
    $self->_enable_hard($self->_channel, $self->_cs, $self->_shdn_pin);
}
sub enable_soft {
    my ($self, $dac) = @_;
    die "no DAC specified\n" if ! defined $dac;
    $self->_enable_soft($self->_channel, $self->_cs, $dac);
}

# private methods

sub _buf {
    my ($self, $buf) = @_;

    if (defined $buf && ($buf < 0 || $buf > 1)){
        die "buf must be either 0 or 1\n";
    }

    $self->{buf} = $buf if defined $buf;
    $self->{buf} = 0 if ! defined $self->{buf};

    return $self->{buf};
}
sub _channel {
    my ($self, $chan) = @_;

    if (defined $chan && ($chan < 0 || $chan > 1)){
        die "channel must be either 0 or 1\n";
    }

    $self->{chan} = $chan if defined $chan;

    return $self->{chan};
}
sub _cs {
    my ($self, $cs) = @_;

    if (defined $cs && ($cs < 0 || $cs > 63)){
        die "cs param is not a valid GPIO pin number\n";
    }

    $self->{cs} = $cs if defined $cs;

    return $self->{cs};
}
sub _data_lsb {
    # return the data LSB for a model of DAC

    my $self = shift;
    my $bits = $self->_model;

    return 12 - $bits;
}
sub _gain {
    my ($self, $gain) = @_;

    if (defined $gain && ($gain < 0 || $gain > 1)){
        die "gain must be either 0 or 1\n";
    }

    $self->{gain} = $gain if defined $gain;
    $self->{gain} = 1 if ! defined $self->{gain};

    return $self->{gain};
}
sub _model {
    my ($self, $model) = @_;

    if (defined $model && $model =~ /\(d{4})$/){
        my $model_num = $1;

        if (! exists $model_map->{$model_num}){
            die "invalid model param specified\n";
        }

        $self->{model} = $model_map->{$model_num};
    }

    die "no model specified!\n" if ! defined $self->{model};

    return $self->{model};
}
sub _shdn_pin {
    my ($self, $sd) = @_;

    if (defined $sd && ($sd < 0 || $sd > 63)){
        die "shdn param is not a valid GPIO pin number\n";
    }

    $self->{shdn} = $sd if defined $sd;

    return $self->{shdn};
}
sub _vim{};

1;
__END__

=head1 NAME

RPi::DAC::MCP4922 - Interface to the MCP49x2 series digital to analog converters
(DAC) over the SPI bus

=head1 DESCRIPTION

Interface to the MCP49x2 series Digital to Analog Converters (DAC) over the SPI
bus. These units have two onboard DACs, which are modified independently.

=head1 SYNOPSIS

=head1 METHODS

=head1 TECHNICAL INFORMATION

=head1 DEVICE SPECIFICS

The MCP49x2 series chips have two onboard DACs (referred to as DAC A and DAC B).

The 4902 unit provides 8-bit output resolution (value 0-255), the 4912, 10-bit
(0-1023), and the 4922, 12-bit (0-4095).

=head1 DEVICE OPERATION

The MCP49x2 series digital to analog converters (DAC) operate as follows:

    - SHDN pin is an override to physically disable the DACs. It can be tied to
      3.3v+ or 5v+ for always-on, or tied to any GPIO pin so you can control the
      physical shutdown by putting the GPIO pin LOW
    - on startup, put the CS pin to HIGH. This indicates that there is no
      conversation occuring
    - turn the CS pin to LOW to start a conversation
    - send 16 bits (the write register) over the SPI bus while CS is LOW
    - turn the CS pin HIGH to end the conversation
    - as soon as the last bit is clocked in, the specified DAC will update its
      output level

=head2 DEVICE REGISTER

The write register is the same for all devices under the MCP49x2 umbrella, with
the differing devices having differing sizes for the data portion. Following is
a diagram that depicts the register for the different devices, where C<x> shows
that the bit is available, with a C<-> signifying that this bit will be ignored.
Note that a full 16-bits needs to be sent in regardless of chip type.

            |<---------------- Write Command Register --------------->|
            |                   |                                     |
            |<---- control ---->|<------------ data ----------------->|
            ] 15 | 14 | 13 | 12 | 11 10 09 08 07 06 05 04 03 02 01 00 |
            -----------------------------------------------------------
            | ^  |  ^ |  ^ |  ^ |               ^                     |
            |    |    |    |    |                                     |
            |A/B | BUF|GAIN|SHDN|              DATA                   |
            |---------------------------------------------------------|
    MCP4922 | x  |  x |  x |  x |  x  x  x  x  x  x  x  x  x  x  x  x | 12-bit
    MCP4912 | x  |  x |  x |  x |  x  x  x  x  x  x  x  x  x  x  -  - | 10-bit
    MCP4902 | x  |  x |  x |  x |  x  x  x  x  x  x  x  x  -  -  -  - |  8-bit
            -----------------------------------------------------------

=head2 REGISTER BITS

The device register is 16-bits wide.

=head3 DAC SELECT BITS

    bit 15

Specifies which DAC we're writing to with this write.

    Param   Value   DAC
    -------------------

    0       0b0     A
    1       0b1     B

=head3 BUFFERED BITS

    bit 14

Specifies whether to buffer the data (for use with the LATCH pin, if used) or
simply send it straight through to the DAC.

    Param   Value   Result
    ----------------------

    0       0b0     Unbuffered (default)
    1       0b1     Buffered

=head3 GAIN BITS

    bit 13

Specifies the value of the gain amplifier.

    Param   Value   Gain
    --------------------

    0       0b0     2x (Vout = 2 * Vref * D/4096)
    1       0b1     1x (Vout = Vref * D/4096) (default)

=head3 SHUTDOWN BITS

    bit 12

Allows you to programmatically shut down both DACs on the chip.

     Param  Value   Result
     ----------------------

     0      0b0     DACs active (default)
     1      0b1     DACs shut down

=head3 DATA BITS

    bits 11-0

These bits are used to set the output level.

    Model   Value   Bits
    --------------------

    MCP4922 0-4095  12
    MCP4912 0-1023  10
    MCP4902 0-255   8

The 10-bit and 8-bit models simply ignore the last 2 and 4 bits respectively.
=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
