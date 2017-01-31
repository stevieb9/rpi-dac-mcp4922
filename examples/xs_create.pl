use warnings;
use strict;
use feature 'say';

use Inline  C => Config =>
            libs => ['-lwiringPi'],
            clean_after_build => 0,
            name => 'RPi::DAC::MCP4922';
use Inline 'C';

my $chan = 0;
my $cs = 18;
my $buf = 1;
my $gain = 1;
my $shdn = 22;
my $model = 12;

my $b = _reg_init($buf, $gain);

printf("%b\n", $b);
test();

__END__
__C__

#include <stdio.h>
#include <stdint.h>
#include <wiringPi.h>
#include <wiringPiSPI.h>

#define MULT 2

#define DAC_BIT  15
#define BUF_BIT  14
#define GAIN_BIT 13
#define SHDN_BIT 12
#define DATA_MSB 11
#define DATA_LSB  0

int buf;
int channel;
int cs;
int gain;

int _buf (int set_buf){
    /* sets global buf bit config */
    buf = set_buf;
}

int _channel (int set_channel){
    /* sets global channel bit config */
    buf = set_channel;
}

int _cs (int set_cs){
    /* sets global CS bit config */
    buf = set_cs;
}

int _gain (int set_gain){
    /* sets global gain bit config */
    gain = set_gain;
}

int _reg_init (){

    /* sets the initial register values */

    int bits = 0;

    if (set_buf){
        bits |= 1 << BUF_BIT;
    }

    if (set_gain){
        bits |= 1 << GAIN_BIT;
    }

    return bits;
}

int _disable_soft (int channel, int cs, int dac){

    int bits = _reg_init();
}
void test (){
    printf("%d, %d\n", buf, gain);
}



