LIBRARY IEEE;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all; 

--pulse generator from the lecture slides
ENTITY PulseGenerate IS
	PORT (clock, reset, button : IN std_logic; --clock, reset, and the button that we will be generating a pulse for
			pulse : OUT std_logic); -- output pulse
END PulseGenerate;

ARCHITECTURE Behaviour OF PulseGenerate IS
SIGNAL D, O : std_logic; -- output signals for 2 flip flops
BEGIN
	PROCESS (clock, reset) --begin process sensitive to clock
		BEGIN
			IF reset = '1' THEN
				D <= '1'; --set reset
			ELSIF rising_edge(clock) THEN --on every clock rising edge 
				D <= button; --feed the button raw input through the first flip flop
			END IF;
	END PROCESS;

	PROCESS (clock, reset) --begin second process sensitive to clock (FF2)
		BEGIN
			IF reset = '1' THEN
				O <= '1'; --set reset
			ELSIF rising_edge(clock) THEN --on every clock rising edge
				O <= D; --feed the D output from the first flip flop to the output
			END IF;
	END PROCESS;

pulse <= (NOT D) AND O; --the final pulse output is O AND D', which is reversed because the FPGA keys are active low
--how this generates a pulse: raw button presses are fed through the first flipflop on every clock edge and stored 
--in D. since its active low, it would be 0. then its complement 1 is fed through an AND gate with O, which is also 1,
--so the AND gate outputs one on that clock edge. However, on the next clock edge, the D 0 value is fed through the second
--flip flop, turning O to 0, and putting the pulse output back to 0. This allows for the output to be high for one clock cycle,
--which is useful to not accidentally allow more inputs to be detected than you intended.
--instead of 00011111000000 you would get something more like: 00010000000.


END Behaviour;
				