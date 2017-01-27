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


=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
