
  freqscan.pl -- use arrow keys to invoke changes in Adafruit si5351A clock gen

	This script configures clk0 of the Adafruit si5351A board from a I2C
	capable SBC.. My setup is a headless BBB some distance away using SSH.  
	For this reason, I did not use a rotary encoder as I first considered.  
	Instead, I use the arrow keys unbuffered for quick response.

   
	            up -- increase frequency
            down -- decrease frequency
           right -- increase scale
            left -- decrease scale
            enter ... terminate program
   

  invocation:
       [JSON=1] ./freqscan.pl 2>/dev/null

      ignore stderr unless you'd like to see debug output
       invoke with JSON support if you'd like to build a json database

       on my BeagleBone Black ( BBB not latest nor fastest sbc ), JSON database
       has minimal benefit.  Ditto the cache (hash) that memoizes frequencies
       already computed.

       Modules needed:
          Term::ReadKey -- no buffer on input
          Time::HiRes   -- don't peg processor waiting for input
          JSON          -- store details of configuration per frequency

       I2C considerations:
         the Adafruit board that I have uses 0x60 as the address, ymmv.
         I use i2cbus = 2 ... ymmv ... adjust in the Fields.pm
         I looked into bumping the bus speed to 400Khz, but abandoned the
         effort as having minimal benefit at best.  

       clk0 is the only clock configured by this script.  Please feel free
       to extend this script as you need to.

	my scope isn't capable of verifying frequencies over ~ 30Mhz, but I
	believe that this script is correct up to 150Mhz.  I did not code for
	frequencies > 150Mhz.

	Neither spread spectrum nor phase offset is configured by this script.
  more generally, this script does what it does, not what you might like
	it to do. ( i.e. CLKx_DIS_STATE ).

	Silicon Labs documentation issues:
	  -  no link to report issues with documentation
	  -  https://www.silabs.com/documents/public/data-sheets/Si5351-b.pdf
	  	reports that frequencies down to 2.5kHz supported.  Perhaps 
  	with clock inputs other than the 25Mhz crystal on the Adafruit
	  	board.  Math indicates that the minimum frequency with the Si5351A
	  	is 3.255kHz ( 25 * 15 / 900 / 128 ). 3.256kHz is the min 
  	frequency that this script will configure.
	  - https://www.silabs.com/documents/public/application-notes/AN619.pdf
	    - register 34  -- is this for multisynth NB or multisynth NA ?
	        - page 30 rev 0.7
	    - register 45  -- is this for multisynth0 or multisynth1 ?
	        - page 34 rev 0.7
	    - register 46  -- is this for multisynth0 or multisynth1 ?
	        - page 35 rev 0.7
	    - register 47 [3:0] -- is this for multisynth0 or multisynth1 ?
	        - page 35 rev 0.7
	    - register 48  -- is this for multisynth0 or multisynth1 ?
	        - page 35 rev 0.7
	    - register 49  -- is this for multisynth0 or multisynth1 ?
	        - page 36 rev 0.7

