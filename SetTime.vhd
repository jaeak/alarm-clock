LIBRARY IEEE;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all; 

--This entity is specifically to drive signals to set a time
ENTITY SetTime IS
	PORT ( clock, reset, increment, toggle : IN std_logic; -- 4 inputes, clock reset. increment to increment a specific value
																				--toggle to toggle between which value you are setting
			 sechold, minhold, hrhold, incsec, incmin, inchr : OUT std_logic
			 ); --outputs will be 1 bit signals that control which value is being incremented, and which values are held
END SetTime;

ARCHITECTURE Behaviour OF SetTime IS

TYPE change IS (sec, min, hr); --type for the sub FSM. state in this case is what value of the clock your changing

SIGNAL state : change;

BEGIN

--begin process sensitive to the clock
PROCESS (clock)
	BEGIN
		IF rising_edge(clock) THEN --on the rising edge
			IF reset = '0' THEN
				state <= sec; --default state is changing the seconds digits
			ELSIF toggle = '1' THEN --if toggle output is signaled
				CASE state IS
					WHEN sec => --when state is in seconds
						state <= min; --cycle to minutes
					WHEN min => --when it is minutes
						state <= hr; --cycle to hours
					WHEN hr => --when hours
						state <= sec; --return back to minutes. This is the full loop when you are in set time mode
				END CASE;
			END IF;
		END IF;
	END PROCESS;

sechold <= '0' WHEN state = sec ELSE '1'; --hold seconds (meaning freeze its value) unless you are changing its value
minhold <= '0' WHEN state = min ELSE '1'; --same thing for minutes
hrhold <= '0' WHEN state = hr ELSE '1'; --and hours
	
incsec <= increment WHEN state = sec ELSE '0'; --when state is seconds, increment signal (which will be a button) will increment seconds only, otherwise seconds wont be incremented
incmin <= increment WHEN state = min ELSE '0'; --increment signal goes to minutes when state is minutes otherwise frozen
inchr <= increment WHEN state = hr ELSE '0'; --same with hours.

END Behaviour;