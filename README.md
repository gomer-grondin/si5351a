
  freqscan.pl -- use arrow keys to invoke changes in Adafruit si5351A clock gen

	This script configures clk0 of the Adafruit si5351A board from a I2C
	capable SBC.. My setup is a headless BBB some distance away using SSH.  
	For this reason, I did not use a rotary encoder as I first considered.  
	Instead, I use the arrow keys unbuffered for quick response.  Also, the
	keyboard is needed in the latest version to choose whether to use
	an integer or fractional solution.

    up -- increase frequency
    down -- decrease frequency
    right -- increase scale
    left -- decrease scale
     's' -- show solution
     'i' -- use integer solution
     'f' -- use fractional solution
    enter ... terminate program

  invocation:
       [INTEGER=1] [JSON=1] ./freqscan.pl [freq] 2>/dev/null

       ignore stderr unless you'd like to see debug output
       invoke with JSON support if you'd like to build a JSON database

  INTEGER Solution:
       This version of the script supports integer solutions... sort of.
       in the CalcFreq.pm module, 31 frequencies are identified as problems
       for the integer solution.  There are probably more.
       I have not identified what causes these frequencies to be problems,
       but I doubt that it is this script.  My gratitude to any one who
       demonstrates that I am mistaken in this assertion.  I do intend to
       post to the Silicon Labs forum, requesting their assistance.

       to compensate, I now recommend that the JSON option be used to store
       the solutions per frequency.  If your desired frequency uses an
       integer solution that your oscillosope contradicts, use the 'f' key
       to use a fractional solution, and store that solution in your JSON
       database.  An example JSON database has been included in this version
       that "corrects" the 31 identified problem frequencies to use a 
       fractional solution.

       IF you've chosen to enable the integer solution mode, this version 
       of the script defaults to fractional solution, but 
       attempts to "upgrade" to an integer solution behind the scene during
       slack time.  This is how problem integer solutions can find their
       way into your JSON database.  Use the 'f' key to remedy this.
       
  /INTEGER Solution:

       Modules needed:
          Term::ReadKey -- no buffer on input
          Time::HiRes   -- don't peg processor waiting for input
          JSON          -- store details of configuration per frequency

       I2C considerations:
         the Adafruit board that I have uses 0x60 as the address, ymmv.
         I use i2cbus = 2 ... ymmv ... adjust in the Fields.pm
         I looked into bumping the bus speed to 400Khz, but abandoned the
         effort as having minimal benefit at best.  

        Phase offset:
          if neither JSON nor INTEGER mode is requested, phase offset is 
          enabled.  use the 'o' and 'p' keys to adjust the offset of clk1 to
          clk0.

	my scope isn't capable of verifying frequencies over ~ 30Mhz, but I
	believe that this script is correct up to 150Mhz.  I did not code for
	frequencies > 150Mhz.

	spread spectrum is not configured by this script.

	Silicon Labs documentation issues:
	  -  https://www.silabs.com/documents/public/data-sheets/Si5351-b.pdf
	  	reports that frequencies down to 2.5kHz supported.  Perhaps 
	  	with clock inputs other than the 25Mhz crystal on the Adafruit
	  	board.  
	  	Math indicates that the minimum frequency with the Si5351A
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

