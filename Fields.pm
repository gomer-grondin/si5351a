package Fields;
#     for the SI5351A from Adafruit  ... clock generator
#     https://www.silabs.com/documents/public/application-notes/AN619.pdf
#

my $ic2address = '0x60';
my $ic2bus = 2;
my $get = "/usr/sbin/i2cget -y $ic2bus $ic2address ";
my $set = "/usr/sbin/i2cset -y $ic2bus $ic2address ";

my $cache;

sub flush_cache {
  my( $v, $i, $r );
  for $r ( sort { $a<=>$b } keys %$cache ) {
	if( $cache->{$r}{'dirty'} ) {
	    $cache->{$r}{'dirty'} = 0;
	    $v = $cache->{$r}{'value'};
 	    $i = "$set $r $v b";
	    system( $i );
	    warn "$i\n";
        }
  }
}

sub one_bit {
  my( $name, $regnum, $regbit, $val ) = @_;
  defined $val or die "no value supplied to $name";
  $val > 0 and $val = 1;
  unless( exists $cache->{$regnum} ) {
      my $i = "$get $regnum b";
      warn "$i\n";
      $cache->{$regnum}{'value'} = hex `$i`;
      $cvreg = $cache->{$regnum}{'value'};
  }
  my $cvreg = $cache->{$regnum}{'value'};
  my $cvmask = 2 ** $regbit;
  my $cvbit = $cvreg & $cvmask;
  my $newbit = $val & 1;
  if( $newbit == 0 and $cvbit ) {
    $cache->{$regnum}{'value'} = $cvreg & ( 255 - $cvmask );
    $cache->{$regnum}{'dirty'} = 1;
  } 
  if( $newbit and $cvbit == 0 ) {
    $cache->{$regnum}{'value'} = ( $cvreg | $cvmask );
    $cache->{$regnum}{'dirty'} = 1;
  }
}

sub xtal_cl {
	one_bit( 'xtal_cl',   183, 7, $_[0] & 2 ); 
	one_bit( 'xtal_cl',   183, 6, $_[0] & 1 ); 
}

sub clk0_src {
	one_bit( 'clk0_src',   16, 3, $_[0] & 2 ); 
	one_bit( 'clk0_src',   16, 2, $_[0] & 1 ); 
}

sub clk1_src {
	one_bit( 'clk1_src',   17, 3, $_[0] & 2 ); 
	one_bit( 'clk1_src',   17, 2, $_[0] & 1 ); 
}

sub clk2_src {
	one_bit( 'clk2_src',   18, 3, $_[0] & 2 ); 
	one_bit( 'clk2_src',   18, 2, $_[0] & 1 ); 
}

sub r0_div {
	one_bit( 'r0_div',   44, 4, $_[0] & 1 ); 
	one_bit( 'r0_div',   44, 5, $_[0] & 2 ); 
	one_bit( 'r0_div',   44, 6, $_[0] & 4 ); 
}

sub r1_div {
	one_bit( 'r1_div',   52, 4, $_[0] & 1 ); 
	one_bit( 'r1_div',   52, 5, $_[0] & 2 ); 
	one_bit( 'r1_div',   52, 6, $_[0] & 4 ); 
}

sub twenty_bit {
  my( $name, $r1, $bl, $r2, $r3, $val ) = @_;
  one_bit( $name,  $r1, $bl,     $val & 2 ** 19 ); 
  one_bit( $name,  $r1, $bl - 1, $val & 2 ** 18 ); 
  eighteen_bit( $name, $r1, $bl - 2, $r2, $r3, $val );
}

sub eighteen_bit {
  my( $name, $r1, $bl, $r2, $r3, $val ) = @_;
  one_bit( $name,  $r1, $bl    , $val & 2 ** 17 ); 
  one_bit( $name,  $r1, $bl - 1, $val & 2 ** 16 ); 
  one_bit( $name,  $r2, 7      , $val & 2 ** 15 ); 
  one_bit( $name,  $r2, 6      , $val & 2 ** 14 ); 
  one_bit( $name,  $r2, 5      , $val & 2 ** 13 ); 
  one_bit( $name,  $r2, 4      , $val & 2 ** 12 ); 
  one_bit( $name,  $r2, 3      , $val & 2 ** 11 ); 
  one_bit( $name,  $r2, 2      , $val & 2 ** 10 ); 
  one_bit( $name,  $r2, 1      , $val & 2 **  9 ); 
  one_bit( $name,  $r2, 0      , $val & 2 **  8 ); 
  one_bit( $name,  $r3, 7      , $val & 2 **  7 ); 
  one_bit( $name,  $r3, 6      , $val & 2 **  6 ); 
  one_bit( $name,  $r3, 5      , $val & 2 **  5 ); 
  one_bit( $name,  $r3, 4      , $val & 2 **  4 ); 
  one_bit( $name,  $r3, 3      , $val & 2 **  3 ); 
  one_bit( $name,  $r3, 2      , $val & 2 **  2 ); 
  one_bit( $name,  $r3, 1      , $val & 2 **  1 ); 
  one_bit( $name,  $r3, 0      , $val & 2 **  0 ); 
}

sub clk0_oeb { one_bit( 'clk0_oeb',  3, 0, $_[0] ); }
sub clk1_oeb { one_bit( 'clk1_oeb',  3, 1, $_[0] ); }
sub clk2_oeb { one_bit( 'clk2_oeb',  3, 2, $_[0] ); }
sub clk0_pdn { one_bit( 'clk0_pdn', 16, 7, $_[0] ); }
sub clk1_pdn { one_bit( 'clk1_pdn', 17, 7, $_[0] ); }
sub clk1_pdn { one_bit( 'clk2_pdn', 18, 7, $_[0] ); }
sub ms0_src  { one_bit( 'ms0_src',  16, 5, $_[0] ); }
sub ms0_int  { one_bit( 'ms0_int',  16, 6, $_[0] ); }
sub ms1_src  { one_bit( 'ms1_src',  17, 5, $_[0] ); }
sub ms1_int  { one_bit( 'ms1_int',  17, 6, $_[0] ); }
sub plla_src { one_bit( 'pllb_src', 15, 2, $_[0] ); }
sub pllb_src { one_bit( 'pllb_src', 15, 3, $_[0] ); }
sub fba_int  { one_bit( 'fba_int',  22, 6, $_[0] ); }
sub fbb_int  { one_bit( 'fbb_int',  23, 6, $_[0] ); }
sub plla_rst { one_bit( 'plla_rst', 177, 5, $_[0] ); }
sub pllb_rst { one_bit( 'pllb_rst', 177, 7, $_[0] ); }
sub ssc_en   { one_bit( 'ssc_en',   149, 7, $_[0] ); }

sub ms0_p1 { eighteen_bit( 'ms0_p1', 44, 1, 45, 46, $_[0] ); }
sub ms0_p2 { twenty_bit( 'ms0_p2', 47, 3, 48, 49, $_[0] ); }
sub ms0_p3 { twenty_bit( 'ms0_p3', 47, 7, 42, 43, $_[0] ); }
sub ms1_p2 { twenty_bit( 'ms1_p2', 55, 3, 56, 55, $_[0] ); }
sub msna_p1 { eighteen_bit( 'msna_p1', 28, 1, 29, 30, $_[0] ); }
sub msnb_p1 { eighteen_bit( 'msnb_p1', 36, 1, 37, 38, $_[0] ); }
sub msna_p2 { twenty_bit( 'msna_p2', 31, 3, 32, 33, $_[0] ); }
sub msnb_p2 { twenty_bit( 'msnb_p2', 39, 3, 40, 41, $_[0] ); }
sub msna_p3 { twenty_bit( 'msna_p3', 31, 7, 26, 27, $_[0] ); }
sub msnb_p3 { twenty_bit( 'msnb_p3', 39, 7, 34, 35, $_[0] ); }

1;
