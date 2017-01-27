package RPi::DAC::MCP49XX;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('WiringPi::API', $VERSION);

1;
__END__

=head1 NAME

RPi::DAC::MCP49XX - Interface to the MCP49xx series digital to analog
converters (DAC) over the SPI bus

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head1 TECHNICAL INFORMATION

=head2 DEVICE REGISTER

The write register is the same for all devices under the MCP49xx umbrella, with
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
            | |     |    |    | |               |                     |
            |A/B | BUF|GAIN|SHDN|              DATA                   |
            |---------------------------------------------------------|
    MCP4922 | x  |  x |  x |  x |  x  x  x  x  x  x  x  x  x  x  x  x |
    MCP4912 | x  |  x |  x |  x |  x  x  x  x  x  x  x  x  x  x  -  - |
    MCP4902 | x  |  x |  x |  x |  x  x  x  x  x  x  x  x  -  -  -  - |
            -----------------------------------------------------------

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
