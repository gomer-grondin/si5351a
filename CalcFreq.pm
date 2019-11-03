package CalcFreq;

#
#  given desired frequency output parameters
#

use strict;
use warnings 'all';
use JSON;

{
  my ( $cache, $loaded );
  sub calcfreq {
    my ( $freq, $r ) = @_;
    $freq = sprintf( "%.6g", $freq );
    $loaded or load_json();
    exists $cache->{$freq} and return $cache->{$freq};
    if( $r = fractional( $freq ) ) {
	$cache->{$freq} = $r;
	return $r;
    }
    {};
  }
  sub load_json {
	  $loaded = 1;
	  exists $ENV{'JSON'} or return;
	  open( my $f, "<", "./freq.json" ) or return;
	  my $json = <$f>;
	  close $f or die "unable to close : $!";
	  $cache = from_json( $json );
  }
  sub write_json {
	  exists $ENV{'JSON'} or return;
	  open( my $f, ">", "./freq.json" ) or die "unable to open : $!";
	  my $json = to_json( $cache );
	  print $f $json;
	  close $f or die "unable to close : $!";
  }
}

sub fractional {
  my ( $freq, $done ) = @_;
  my $f1 = $freq / 25; # 25MHZ crystal
  my ( $r, $f2, $d, $ms0_int );
  $ms0_int = 1;
  for ( $r = 0 ; $r <= 7 ; $r++ ) {
    for ( $d = 10 ; $d <= 900 ; $d += 2 ) {
      $f2 = $f1 * $d * 2**$r;
      $f2 < 15 and next;
      $f2 > 90 and next;
      $done = 1;
      last;
    }
    $done and last;
  }
  unless( $done ) {
    $ms0_int = 0;
    for ( $r = 0 ; $r <= 7 ; $r++ ) {
      for ( $d = 9 ; $d <= 900 ; $d += 2 ) {
        $f2 = $f1 * $d * 2**$r;
        $f2 < 15 and next;
        $f2 > 90 and next;
        $done = 1;
        last;
      }
      $done and last;
    }
  }
  if ( $done ) {
     my $ma = int( $f2 );
     my $mc = 1000 * 1000;
     my $mb = sprintf( "%d", ( $f2 - int( $f2 ) ) * $mc );
     my $fba_int = 0;
     $mb == 0 and $f2 % 2 == 0 and $fba_int = 1;
     return { 
	     r0_div => $r,
	     msna_p1 => 128 * $ma + ( int( 128 * $mb / $mc ) ) - 512,
	     msna_p2 => 128 * $mb - ( $mc * int( 128 * $mb / $mc ) ),
	     msna_p3 => $mc,
	     ms0_p1 => 128 * $d - 512,
	     ms0_p2 => 0,
	     ms0_p3 => 0,
	     fba_int => $fba_int,
	     ms0_int => $ms0_int,
	     clk0_src => 3,
	     ms0_src => 0,
	     plla_src => 0,
	     xtal_cl => 3,
     };
  }
  print "$freq .. No solution\n";
  undef;
}

1;


