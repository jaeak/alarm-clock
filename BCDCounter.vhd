LIBRARY IEEE;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all; 

--entity and ports
ENTITY BCDCounter IS
	PORT (reset, clock, Hold, increment, syncrst : IN std_logic; --reset for hard reset, hold to freeze values
			Q : OUT std_logic_vector(3 DOWNTO 0) --increment will be enable, and will allow control over how the values increment
			); --sync reset remains the same
END BCDCounter;

ARCHITECTURE Behaviour OF BCDCounter IS

COMPONENT FF  --use the ff component
    PORT ( clk, reset, D, Hold, enable, syncrst : IN std_logic;
             Q : OUT std_logic
				 );
END COMPONENT;

SIGNAL SIGQ : std_logic_vector (3 downto 0); --signal sigq represents the "next" state of each ff
SIGNAL carry1, carry2, carry3 : std_logic; --carry logic for the counter
SIGNAL O : std_logic_vector (3 downto 0); --O signal is the final, real output of the counter

BEGIN

carry1 <= increment AND O(0); --first carry depends on increment (either user or clock based) and the last output
carry2 <= carry1 AND O(1); --second carry carries if the first 2 outputs are 1 (so 011 will carry, making 100)
carry3 <= carry2 AND O(2); --last carry (0111)

SIGQ(0) <= increment XOR O(0); --next state for the LSB toggles every increment, simple xor with output makes it toggle (TFF)
SIGQ(1) <= O(1) XOR carry1; --next state for the next bit toggles every 2 increments. takes carry xor its own input as input
SIGQ(2) <= O(2) XOR carry2; --this pattern of carry(i) XOR output(i) makes a counter. This one increments when increment is 1
SIGQ(3) <= O(3) XOR carry3; --and is not being held by the hold input

--instantiating each flipflop and port mapping the carry signals, and next input signals appropriately
I0 : FF PORT MAP (clk => clock, reset => reset, syncrst => syncrst, enable => increment, Hold => Hold, D => SIGQ(0), Q => O(0));
I1 : FF PORT MAP (clk => clock, reset => reset, syncrst => syncrst, enable => increment, Hold => Hold, D => SIGQ(1), Q => O(1));
I2 : FF PORT MAP (clk => clock, reset => reset, syncrst => syncrst, enable => increment, Hold => Hold, D => SIGQ(2), Q => O(2));
I3 : FF PORT MAP (clk => clock, reset => reset, syncrst => syncrst, enable => increment, Hold => Hold, D => SIGQ(3), Q => O(3));

--final output
Q <= O;

END Behaviour;