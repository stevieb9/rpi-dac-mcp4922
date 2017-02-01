use warnings;
use strict;

use RPi::DAC::MCP4922;

my $dac = RPi::DAC::MCP4922->new(
    model   => 'MCP4922',
    channel => 0,
    cs      => 18,
);

$dac->set(0, 4095);

sleep 3;
