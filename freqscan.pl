#!/usr/bin/perl
#
#  freqscan.pl -- use arrow keys to invoke changes in Adafruit si5351A clock gen
#
#	This script configures clk0 of the Adafruit si5351A board from a I2C
#	capable SBC.. My setup is a headless BBB some distance away using SSH.  
#	For this reason, I did not use a rotary encoder as I first considered.  
#	Instead, I use the arrow keys unbuffered for quick response.
#
#sub usage {
# print "   up -- increase frequency\n";
# print " down -- decrease frequency\n";
# print "right -- increase scale\n";
# print " left -- decrease scale\n";
# print " enter ... terminate program\n";
#}
#
#  invocation:
#       [JSON=1] ./freqscan.pl 2>/dev/null
#
#       ignore stderr unless you'd like to see debug output
#       invoke with JSON support if you'd like to build a json database
#
#       on my BeagleBone Black ( BBB not latest nor fastest sbc ), JSON database
#       has minimal benefit.  Ditto the cache (hash) that memoizes frequencies
#       already computed.
#
#       Modules needed:
#          Term::ReadKey -- no buffer on input
#          Time::HiRes   -- don't peg processor waiting for input
#          JSON          -- store details of configuration per frequency
#
#       I2C considerations:
#         the Adafruit board that I have uses 0x60 as the address, ymmv.
#         I use i2cbus = 2 ... ymmv ... adjust in the Fields.pm
#         I looked into bumping the bus speed to 400Khz, but abandoned the
#         effort as having minimal benefit at best.  
#
#       clk0 is the only clock configured by this script.  Please feel free
#       to extend this script as you need to.
#
#	my scope isn't capable of verifying frequencies over ~ 30Mhz, but I
#	believe that this script is correct up to 150Mhz.  I did not code for
#	frequencies > 150Mhz.
#
#	Neither spread spectrum nor phase offset is configured by this script.
#	more generally, this script does what it does, not what you might like
#	it to do. ( i.e. CLKx_DIS_STATE ).
#
#	Silicon Labs documentation issues:
#	  -  no link to report issues with documentation
#	  -  https://www.silabs.com/documents/public/data-sheets/Si5351-b.pdf
#	  	reports that frequencies down to 2.5kHz supported.  Perhaps 
#	  	with clock inputs other than the 25Mhz crystal on the Adafruit
#	  	board.  Math indicates that the minimum frequency with the Si5351A
#	  	is 3.255kHz ( 25 * 15 / 900 / 128 ). 3.256kHz is the min 
#	  	frequency that this script will configure.
#	  - https://www.silabs.com/documents/public/application-notes/AN619.pdf
#	    - register 34  -- is this for multisynth NB or multisynth NA ?
#	        - page 30 rev 0.7
#	    - register 45  -- is this for multisynth0 or multisynth1 ?
#	        - page 34 rev 0.7
#	    - register 46  -- is this for multisynth0 or multisynth1 ?
#	        - page 35 rev 0.7
#	    - register 47 [3:0] -- is this for multisynth0 or multisynth1 ?
#	        - page 35 rev 0.7
#	    - register 48  -- is this for multisynth0 or multisynth1 ?
#	        - page 35 rev 0.7
#	    - register 49  -- is this for multisynth0 or multisynth1 ?
#	        - page 36 rev 0.7
#
use lib '.';
use CalcFreq;
use Fields;
use Term::ReadKey;
use Time::HiRes qw( usleep );
use strict;
use warnings 'all';

# 27;91;65  up
# 27;91;66  down
# 27;91;67  right
# 27;91;68  left

my ( $scale, $freq ) = ( 1, .003256 );  # min frequency
{
  my $s = { 
	  1 => '1hz',
	  10 => '10hz',
	  100 => '100hz',
	  1000 => '1Khz',
	  10000 => '10Khz',
	  100000 => '100Khz',
	  1000000 => '1Mhz',
	  10000000 => '10Mhz',
  };

  sub report {
    my( $r ) = @_;
    $scale or $scale = 1000000;
    my $f  = $freq;
    my $pf = $freq < 1 ? 'Khz' : 'Mhz';
    $freq < 1 and $f *= 1000;
    printf( "Frequency = %6f %s, Scale = %s\n", $f, $pf, $s->{$scale} );
    keys %$r or return;
    Fields::clk0_oeb( 1 );  # output disable
    Fields::flush_cache();
    for( sort keys %$r ) { 
	    my $f = "Fields::$_( $r->{$_} )";
	    warn "$f\n";
	    eval "$f";
	    $@ and warn $@;
    }
    Fields::flush_cache();
    Fields::plla_rst( 1 );  # reset 
    Fields::flush_cache();
    Fields::plla_rst( 0 );  # self clearing bit .. update register cache
    Fields::clk0_oeb( 0 );  # output enable
    Fields::flush_cache();
  }

  sub left {   # decrease scale
    if ( $scale > 1 ) {
       $scale /= 10;
       report( {} );
    } else {
       print "minimum frequency .. parameter limit reached\n";
    }
  }
  sub right {  # increase scale
    if ( $scale < 10000000 ) {  # 10 mhz
    	$scale *= 10;
        report( {} );
    } else {
        print "maximum frequency .. parameter limit reached\n";
    }
  }
  sub up {     # increase frequency
    $freq += $scale / 1000000;
    report( CalcFreq::calcfreq( $freq ) );
  }
  sub down {   # decrease frequency
    $freq -= $scale / 1000000;
    $freq > 0 or $freq += $scale / 1000000;
    report( CalcFreq::calcfreq( $freq ) );
  }
} 

sub usage {
 print "   up -- increase frequency\n";
 print " down -- decrease frequency\n";
 print "right -- increase scale\n";
 print " left -- decrease scale\n";
 print " enter ... terminate program\n";
}

usage();
report( CalcFreq::calcfreq( $freq ) );

ReadMode 4;
my ( $key, $keystack );
while( 1 ) {
  while( not defined ( $key = ReadKey(-1))) {
      usleep( 10000 );
  }
  if( $key eq "\n" ) {
    CalcFreq::write_json();
    last;
  }
  my $ascii = ord($key);
  push @$keystack, $ascii;
  next if( $ascii < 65 or $ascii > 68 );
  my $char3 = pop @$keystack;
  my $char2 = pop @$keystack;
  my $char1 = pop @$keystack;
  if( $char1 == 27 and $char2 == 91 ) {
    left()  if $char3 == 68;
    right() if $char3 == 67;
    down()  if $char3 == 66;
    up()    if $char3 == 65;
  }
}
ReadMode 0;
1;