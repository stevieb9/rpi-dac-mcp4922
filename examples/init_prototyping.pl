use warnings;
use strict;
use feature 'say';

use Bit::Manip qw(:all);
use RPi::WiringPi;

my $spi_chan = 0;

my $pi = RPi::WiringPi->new;
my $adc = $pi->adc;
my $spi = $pi->spi($spi_chan);

my $cs_pin = $pi->pin(18);

# drop chip select to LOW to start conversation with the DAC

$cs_pin->write(LOW);

# bit manip to do some prototype testing

my $register = bit_set(0, 0, 16, 0);
say $register;
say $adc->percent;


# put chip select to HIGH to end conversation with the DAC

$cs_pin->write(LOW);



