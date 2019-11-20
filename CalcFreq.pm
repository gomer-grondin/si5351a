package CalcFreq;

#
#  given desired frequency output parameters
#

use strict;
use warnings 'all';
use JSON;

{
  my ( $cache, $loaded, $integer_check );
  sub increase_phoff {
    exists $cache->{'clk1_phoff'} or $cache->{'clk1_phoff'} = -1;
    $cache->{'clk1_phoff'} < 127  or $cache->{'clk1_phoff'} = -1; 
    ++$cache->{'clk1_phoff'};
  }

  sub decrease_phoff  {
    exists $cache->{'clk1_phoff'} or $cache->{'clk1_phoff'} = 128;
    $cache->{'clk1_phoff'} > 0    or $cache->{'clk1_phoff'} = 128; 
    --$cache->{'clk1_phoff'};
  }

  sub show_solution {
    my ( $freq ) = @_;
    $freq = sprintf( "%.6g", $freq );
    print "\n";
    for( sort keys %{$cache->{$freq}} ) {
      print "$_: " . $cache->{$freq}{$_} . "\n";
    }
  }
  sub update_cache {
    my ( $freq, $r ) = @_;
    $freq = sprintf( "%.6g", $freq );
    $cache->{$freq} = $r;
  }
  sub check_integer {
    my $freq = pop @$integer_check or return undef;
    exists $ENV{'INTEGER'}         or return undef;
    # 20.5 Mhz Problem
    # 19.5 Mhz Problem
    # 18.5 Mhz Problem
    # 16.5 Mhz Problem
    # 15.5 Mhz Problem
    # 14.5 Mhz Problem
    # 13.5 Mhz Problem
    #  8.8 Mhz Problem
    #  8.6 Mhz Problem
    #  8.4 Mhz Problem
    #  8.2 Mhz Problem
    #  7.8 Mhz Problem
    #  7.6 Mhz Problem
    #  7.4 Mhz Problem
    #  7.2 Mhz Problem
    #  6.8 Mhz Problem
    #  6.6 Mhz Problem
    #  6.4 Mhz Problem
    #  6.2 Mhz Problem
    #  5.8 Mhz Problem
    #  5.4 Mhz Problem
    #  5.2 Mhz Problem
    #  4.8 Mhz Problem
    #  4.3 Mhz Problem
    #  4.1 Mhz Problem
    #  3.9 Mhz Problem
    #  3.7 Mhz Problem
    #  3.3 Mhz Problem
    #  3.1 Mhz Problem
    #  2.9 Mhz Problem
    #  2.7 Mhz Problem
    if( my $r = integer( $freq ) ) { $cache->{$freq} = calc_register( $r ); }
    return 1;
  }

  sub calcfreq {
    my ( $freq, $r ) = @_;
    $freq = sprintf( "%.6g", $freq );
    $loaded or load_json();
    exists $cache->{$freq} and return $cache->{$freq};
    if( $r = fractional( $freq ) ) {
	$cache->{$freq} = calc_register( $r );
	push @$integer_check, $freq;
        return $cache->{$freq};
    }
    print "\n$freq .. No solution";
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

sub _solve_for_r {
	my( $freq ) = @_;
	for( my $r = 0 ; $r < 8 ; $r++ ) {
		$freq * 900 * 2**$r > 15 and return $r;
	}
	die "unable to calc r for $freq";
}

sub integer {
  my ( $freq, $done, $r, $m, $d ) = @_;
  exists $ENV{'INTEGER'} or return undef;
  my $f1 = sprintf( "%.6g", $freq / 25 ); # 25MHZ crystal
  $r = _solve_for_r( $f1 );
  for ( $m = 16 ; $m <= 90 ; $m += 2 ) {
    for ( $d = 10 ; $d <= 900 ; $d += 2 ) {
      my $f2 = sprintf( "%.6g", $m / $d / 2 ** $r );
      $done = 1 if( $f1 eq $f2 );
      $done and last;
    }
    $done and last;
  }
  $done and return { r => $r, m => $m, d => $d, };
  undef;
}

sub fractional {
  my ( $freq ) = @_;
  my $f1 = sprintf( "%.6g", $freq / 25 ); # 25MHZ crystal
  my ( $done, $r, $d, $m );
  $r = _solve_for_r( $f1 );
  for ( $d = 10 ; $d <= 900 ; $d += 2 ) {
      $m = $f1 * $d * 2**$r;
      $m < 15 and next;
      $m > 46 and next;
      $done = 1;
      last;
  }
  $done and return { r => $r, m => $m, d => $d, };
  undef;
}

sub calc_register {
  my( $s ) = @_;
  my $ma = int( $s->{m} );
  my $mc = 1000 * 1000;
  my $mb = sprintf( "%d", ( $s->{m} - int( $s->{m} ) ) * $mc );
  my ( $fba_int, $ms0_int, $ms1_int ) = ( 0, 0, 0 );
  if( exists $ENV{'INTEGER'} ) {
    $mb == 0 and $s->{m} % 2 == 0 and $fba_int = 1;
    $ms0_int = 1;
    $ms1_int = 1;
  }
  return { 
	     r0_div => $s->{r},
	     r1_div => $s->{r},
	     msna_p1 => 128 * $ma + ( int( 128 * $mb / $mc ) ) - 512,
	     msna_p2 => 128 * $mb - ( $mc * int( 128 * $mb / $mc ) ),
	     msna_p3 => $mc,
	     ms1_p1 => 128 * $s->{d} - 512,
	     ms1_p2 => 0,
	     ms1_p3 => 0,
	     ms0_p1 => 128 * $s->{d} - 512,
	     ms0_p2 => 0,
	     ms0_p3 => 0,
	     fba_int => $fba_int,
	     ms0_int => $ms0_int,
	     ms1_int => $ms1_int,
	     clk0_src => 3,
	     clk1_src => 3,
	     ms0_src => 0,
	     ms1_src => 0,
	     plla_src => 0,
	     xtal_cl => 3,
     };
}

1;


