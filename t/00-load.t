#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::DAC::MCP49XX' ) || print "Bail out!\n";
}

diag( "Testing RPi::DAC::MCP49XX $RPi::DAC::MCP49XX::VERSION, Perl $], $^X" );
