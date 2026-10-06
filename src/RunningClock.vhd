LIBRARY IEEE;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all; 

--running clock puts all the BCDCounters together to create a running clock which can run, hold, and remember values
ENTITY RunningClock IS
			--port inputs are clock reset, and hold inputs for each time value
			--hold values are signals which hold the current value if they are high.
			--this is good for storing values, and also for memorizing values as well
			--seperate increment inputs also make this entity versatile as you can choose which
			--value to increment induvidually, which is useful for setting the clock
	PORT ( clock, reset, holdsec, holdmin, holdhr, incsec, incmin, inchr : IN std_logic;
			 Seg0, Seg1, Seg2, Seg3, Seg4, Seg5 : OUT std_logic_vector (3 downto 0) -- 4 bit outputs for each BCD digit
			 );
END RunningClock;

ARCHITECTURE Behaviour OF RunningClock IS
--use both BCDCounters as components, we need 2 60s for minutes and seconds, and a 24 for hours
COMPONENT BCDCounter60 
	PORT (reset, clock, Hold, increment, syncrst : IN std_logic;
			O0, O1 : OUT std_logic_vector(3 DOWNTO 0)
			);
END COMPONENT;

COMPONENT BCDCounter24 
	PORT (reset, clock, Hold, increment, syncrst : IN std_logic;
			O0, O1 : OUT std_logic_vector(3 DOWNTO 0)
			);
END COMPONENT;

SIGNAL sec0, sec1 : std_logic_vector(3 downto 0); --the seconds ones and tens digits signal
SIGNAL min0, min1 : std_logic_vector(3 downto 0); --the minutes ones and tens digits signal
SIGNAL hr0, hr1   : std_logic_vector(3 downto 0); --the hours ones and tens digits signal

BEGIN

--port map all the inputs to the outputs of each bcdcounter respective to the clock values
--reset and clock is shared amongst them all. Each value gets its own hold value, so we can later chose
--which values we want to freeze, or remember (useful for setting time and alarm). each value also gets
--its own induvidual increment. If clock is running, then the ones increment will be constant and the others
--will depend on the wraparound from the previous digits. syncreset is 0 as it is not needed. each
--digits output is then fed into the appropriate signal
Seconds : BCDCounter60 PORT MAP (reset => reset, clock => clock, Hold => holdsec, increment => incsec, syncrst => '0', O0 => sec0, O1 => sec1);
Minutes : BCDCounter60 PORT MAP (reset => reset, clock => clock, Hold => holdmin, increment => incmin, syncrst => '0', O0 => min0, O1 => min1);
Hours : BCDCounter24 PORT MAP (reset => reset, clock => clock, Hold => holdhr, increment => inchr, syncrst => '0', O0 => hr0, O1 => hr1);

Seg0 <= sec0;
Seg1 <= sec1;
Seg2 <= min0;
Seg3 <= min1;
Seg4 <= hr0; --outputs to seg
Seg5 <= hr1;

END Behaviour;