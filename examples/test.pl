use warnings;
use strict;
use feature 'say';

use RPi::DAC::MCP4922;
use RPi::ADC::ADS;

my $adc = RPi::ADC::ADS->new;

my $dac = RPi::DAC::MCP4922->new(
    model   => 'MCP4922',
    channel => 1,
    cs      => 18,
);

$dac->set(0, 4095);
$dac->set(1, 4095);

say "0: " . $adc->percent(0) . " %";
say "1: " . $adc->percent(1) . " %";

sleep 2;

$dac->set(0, 0);
$dac->set(1, 0);

for (0..4095){
    next if ($_ != 4095 && $_ != 0) && $_ % 100 != 1;

    $dac->set(0, $_);
    $dac->set(1, 4095 - $_);

    say "0: " . $adc->percent(0) . " %";
    say "1: " . $adc->percent(1) . " %";

    select(undef, undef, undef, 0.05);
}

