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

# turn the shutdown pin to HIGH

$shdn_pin->mode(OUTPUT);
$shdn_pin->write(HIGH);

 # say $shdn_pin->read;

# drop chip select to LOW to start conversation with the DAC

$cs_pin->write(LOW);
 # say $cs_pin->read;

# create the 16-bit register, and set the MSB

my $register = bit_set(0, 0, 16, 32768);
say bit_bin($register);

# set the gain register bit

$register = bit_set($register, 13, 1, 1);
say bit_bin($register);

# set data

$register = bit_set($register, 0, 12, 4095);
say bit_bin($register);

# go HIGH to tell the IC we're done clocking in bits

$cs_pin->write(HIGH);

say $adc->percent;




