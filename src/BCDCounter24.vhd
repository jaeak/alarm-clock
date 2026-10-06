LIBRARY IEEE;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all; 

--same BCDCounter as the 60 seconds, only it resets entirely at 24
ENTITY BCDCounter24 IS
	PORT (reset, clock, Hold, increment, syncrst : IN std_logic; --same ports
			O0, O1 : OUT std_logic_vector(3 DOWNTO 0)
			);
END BCDCounter24;

ARCHITECTURE Behaviour OF BCDCounter24 IS

COMPONENT BCDCounter --instantiate BCDCounter
	PORT (reset, clock, Hold, increment, syncrst : IN std_logic;
			Q : OUT std_logic_vector(3 DOWNTO 0)
			);
END COMPONENT;

SIGNAL Q0, Q1 : std_logic_vector (3 downto 0); --output signals
SIGNAL istwentythree : std_logic; --check if the number is 23 or larger
SIGNAL isnine : std_logic; --check if the ones position is a 9 or larger

BEGIN
	
isnine <= Q0(3) AND Q0(0); --the ones is a 9 when Q0s bit 0, and bit 3 are 1 (1001)
istwentythree <= (Q0(1) AND Q0(0)) AND Q1(1); --the entire number is 23 when Q0 bits are 0011 (3) and Q1 is (0010)

--port map 2 BCDCounters. ones position increments whenever increment is one
--two reset conditions for the ones: either when user forces it, if its 9 and it increments again, or if the number is 23 and it increments
--for the tens, it only increments if an increment signal is recieved, and the ones position is the value 9
--the tens resets either when its forced, or if the number is 23 and increment signal is recieved
I0 : BCDCounter PORT MAP (reset => reset, clock => clock, Hold => Hold, increment => increment, syncrst => syncrst OR (increment AND isnine) OR (increment AND istwentythree), Q => Q0);
I1 : BCDCounter PORT MAP (reset => reset, clock => clock, Hold => Hold, increment => increment AND isnine, syncrst => syncrst OR (increment AND istwentythree), Q => Q1);

O0 <= Q0; -- outputs
O1 <= Q1;

END Behaviour;