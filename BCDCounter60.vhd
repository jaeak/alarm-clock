LIBRARY IEEE;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all; 

--BCDCounter60 takes BCDCounter and makes it count in decimal from 0-59
ENTITY BCDCounter60 IS
	PORT (reset, clock, Hold, increment, syncrst : IN std_logic; --same inputs as before
			O0, O1 : OUT std_logic_vector(3 DOWNTO 0) --2 4 bit outputs
			);
END BCDCounter60;

ARCHITECTURE Behaviour OF BCDCounter60 IS
--using component BCDCounter
COMPONENT BCDCounter
	PORT (reset, clock, Hold, increment, syncrst : IN std_logic;
			Q : OUT std_logic_vector(3 DOWNTO 0)
			);
END COMPONENT;

SIGNAL Q0, Q1 : std_logic_vector (3 downto 0); --signals to carry the output
SIGNAL isnine : std_logic; --check signal to see if a given output is nine (ones position)
SIGNAL isfive : std_logic; --another check signal to see if a given output is 5 (tens position)

BEGIN
	
isnine <= Q0(3) AND Q0(0); --checking if Q0 is nine (1001) or larger
isfive <= Q1(2) AND Q1(0); --checking if Q1 is five (0101) or larger

--instantiate 2 BCDCounters and port map with the appropriate logic
--the ones will syncrst only when it is forced (by user) or if an increment signal comes in, and the value is nine
--the tens will syncrst only when it is forced by user or if it increments and the number displayed is 59
--the tens will also increment only when an increment signal is recieved, and the ones value is 9.
--this is what enables the 0-59 BCD counting logic we use in our clock for both seconds and minutes
I0 : BCDCounter PORT MAP (reset => reset, syncrst => syncrst OR (increment AND isnine), clock => clock, Hold => Hold, increment => increment, Q => Q0);
I1 : BCDCounter PORT MAP (reset => reset, syncrst => syncrst OR (increment AND isfive AND isnine), clock => clock, Hold => Hold, increment => (increment AND isnine), Q => Q1);

O0 <= Q0; --outputs
O1 <= Q1;

END Behaviour;