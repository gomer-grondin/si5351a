#!/usr/bin/perl
#
#  freqscan.pl -- use arrow keys to invoke changes in Adafruit si5351A clock gen
#
#	This script configures clk0 of the Adafruit si5351A board from a I2C
#	capable SBC.. My setup is a headless BBB some distance away using SSH.  
#	For this reason, I did not use a rotary encoder as I first considered.  
#	Instead, I use the arrow keys unbuffered for quick response.  Also, the
#	keyboard is needed in the latest version to choose whether to use
#	an integer or fractional solution.
#
# print "   up -- increase frequency\n";
# print " down -- decrease frequency\n";
# print "right -- increase scale\n";
# print " left -- decrease scale\n";
# print "  'f' -- use fractional solution\n";
# print "  'i' -- use integer solution\n";
# print "  'o' -- decrease phase offset\n";
# print "  'p' -- increase phase offset\n";
# print "  's' -- show solution\n";
# print "  'u' -- usage\n";
# print " enter ... terminate program\n";
#
#  invocation:
#       [INTEGER=1] [JSON=1] ./freqscan.pl [freq] 2>/dev/null
#
#       ignore stderr unless you'd like to see debug output
#       invoke with JSON support if you'd like to build a JSON database
#
#  INTEGER Solution:
#       This version of the script supports integer solutions... sort of.
#       in the CalcFreq.pm module, 31 frequencies are identified as problems
#       for the integer solution.  There are probably more.
#       I have not identified what causes these frequencies to be problems,
#       but I doubt that it is this script.  My gratitude to any one who
#       demonstrates that I am mistaken in this assertion.  I do intend to
#       post to the Silicon Labs forum, requesting their assistance.
#
#       to compensate, I now recommend that the JSON option be used to store
#       the solutions per frequency.  If your desired frequency uses an
#       integer solution that your oscillosope contradicts, use the 'f' key
#       to use a fractional solution, and store that solution in your JSON
#       database.  An example JSON database has been included in this version
#       that "corrects" the 31 identified problem frequencies to use a 
#       fractional solution.
#
#       IF you've chosen to enable the integer solution mode, this version 
#       of the script defaults to fractional solution, but 
#       attempts to "upgrade" to an integer solution behind the scene during
#       slack time.  This is how problem integer solutions can find their
#       way into your JSON database.  Use the 'f' key to remedy this.
#       
#  /INTEGER Solution:
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
#       Phase offset:
#         if neither JSON nor INTEGER mode is requested, phase offset is 
#         enabled.  use the 'o' and 'p' keys to adjust the offset of clk1 to
#         clk0.
#
#	my scope isn't capable of verifying frequencies over ~ 30Mhz, but I
#	believe that this script is correct up to 150Mhz.  I did not code for
#	frequencies > 150Mhz.
#
#	spread spectrum is not configured by this script.
#
#	Silicon Labs documentation issues:
#	  -  https://www.silabs.com/documents/public/data-sheets/Si5351-b.pdf
#	  	reports that frequencies down to 2.5kHz supported.  Perhaps 
#	  	with clock inputs other than the 25Mhz crystal on the Adafruit
#	  	board.  
#	  	Math indicates that the minimum frequency with the Si5351A
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
use Time::HiRes qw( usleep time );
use strict;
use warnings 'all';

# 27;91;65  up
# 27;91;66  down
# 27;91;67  right
# 27;91;68  left

my ( $scale, $freq, $phoff ) = ( 1000, 1, 0 );
$ARGV[0] and $freq = $ARGV[0];

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
    printf( "\nFrequency = %6f %s, Scale = %s, Phase Offset = %d", 
	                                      $f, $pf, $s->{$scale}, $phoff );
    keys %$r or return;
    {
      my $mode = ' FRACTIONAL ';
      if( exists $ENV{'INTEGER'} ) {
        if( exists $r->{'msna_p2'} and $r->{'msna_p2'} == 0 and 
            exists $r->{'fba_int'} and $r->{'fba_int'} == 1 
	  ) { $mode = ' INTEGER '; }
      } 
      print $mode;
    }
    Fields::clk0_oeb( 1 );  # output disable
    Fields::clk1_oeb( 1 );  # output disable
    Fields::clk0_pdn( 1 );  # power down
    Fields::clk1_pdn( 1 );  # power down
    Fields::flush_cache();
    for( sort keys %$r ) { 
	    my $f = "Fields::$_( $r->{$_} )";
	    warn "$f\n";
	    eval "$f";
	    $@ and warn $@;
    }
    Fields::flush_cache();
    Fields::clk0_pdn( 0 );  # power up 
    Fields::clk1_pdn( 0 );  # power up 
    Fields::flush_cache();
    Fields::plla_rst( 1 );  # reset 
    Fields::flush_cache();
    Fields::plla_rst( 0 );  # self clearing bit .. update register cache
    Fields::flush_cache();
    Fields::clk0_oeb( 0 );  # output enable
    Fields::clk1_oeb( 0 );  # output enable
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
    $freq > .003255 or $freq += $scale / 1000000;
    report( CalcFreq::calcfreq( $freq ) );
  }
} 

sub usage {
 print "\n";
 print "USAGE: [INTEGER=1] [JSON=1] ./freqscan [freq] 2>/dev/null\n";
 print "   up -- increase frequency\n";
 print " down -- decrease frequency\n";
 print "right -- increase scale\n";
 print " left -- decrease scale\n";
 print "  'f' -- use fractional solution\n";
 print "  'i' -- use integer solution\n";
 print "  'o' -- decrease phase offset\n";
 print "  'p' -- increase phase offset\n";
 print "  's' -- show solution\n";
 print "  'u' -- usage\n";
 print " enter ... terminate program\n";
}

usage();
Fields::clk0_phoff( 0 );
Fields::clk1_phoff( 0 );
report( CalcFreq::calcfreq( $freq ) );

ReadMode 4;
my ( $key, $keystack );
while( 1 ) {
  my $start = time();
  while( not defined ( $key = ReadKey(-1))) {
      my $sleeptime;
      if( time() - $start > 2 ) {        # no key input for 2 seconds
        # can fractional solution be upgraded?
        if( CalcFreq::check_integer() ) { $sleeptime = 10000; }
	$sleeptime or $sleeptime = 40000;
        usleep( $sleeptime );
      }
  }

  if( $key eq 's' ) { CalcFreq::show_solution( $freq ); next; }
  if( $key eq 'u' ) { usage(); next; }
  if( $key eq 'o' ) { 
    if( exists $ENV{'INTEGER'} ) {
      print " INTEGER mode enabled, no phase offset "; 
      next;
    }
    if( exists $ENV{'JSON'} ) {
      print " JSON mode enabled, no phase offset "; 
      next;
    }
    $phoff = CalcFreq::decrease_phoff(); 
    Fields::clk0_phoff( 0 );
    Fields::clk1_phoff( $phoff );
    Fields::flush_cache();
    report( CalcFreq::calcfreq( $freq ) );
    next; 
  }
  if( $key eq 'p' ) {
    if( exists $ENV{'INTEGER'} ) {
      print " INTEGER mode enabled, no phase offset "; 
      next;
    }
    if( exists $ENV{'JSON'} ) {
      print " JSON mode enabled, no phase offset "; 
      next;
    }
    $phoff = CalcFreq::increase_phoff(); 
    Fields::clk0_phoff( 0 );
    Fields::clk1_phoff( $phoff );
    Fields::flush_cache();
    report( CalcFreq::calcfreq( $freq ) );
    next; 
  }

  if( $key eq 'f' ) {
    if( my $r = CalcFreq::fractional( $freq ) ) {
      my $r2 = CalcFreq::calc_register( $r );
      CalcFreq::update_cache( $freq, $r2 );
      print " FRACTIONAL solution overwrote current solution";
      report( CalcFreq::calcfreq( $freq ) );
    }
    next;
  }

  if( $key eq 'i' ) {
    if( my $r = CalcFreq::integer( $freq ) ) {
      my $r2 = CalcFreq::calc_register( $r );
      CalcFreq::update_cache( $freq, $r2 );
      print " INTEGER solution overwrote current solution";
      report( CalcFreq::calcfreq( $freq ) );
    } else {
      print " no INTEGER solution";
    }
    next;
  }

  if( $key eq "\n" ) {
    print "\n";
    while( CalcFreq::check_integer() ) {;}
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
