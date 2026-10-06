--Sumair and Jack
LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Same prescale as lab 6 with 25 bit
ENTITY PreScale IS
	GENERIC (dataw : integer := 25); --generic 25 bit datawidth
	PORT (InClock : IN std_logic;
			OutClock : OUT std_logic
			);
END PreScale;


ARCHITECTURE Behaviour OF PreScale IS
SIGNAL x : unsigned (dataw - 1 downto 0);

BEGIN 
	PROCESS (InClock)
		BEGIN
			IF InClock'EVENT AND InClock = '1'
				THEN x <= x + 1;
			END IF;
		END PROCESS;
		OutClock <= x(dataw - 1);
END Behaviour;