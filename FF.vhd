LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

--basic D flip flop with syncronous reset and hold
ENTITY FF IS
    PORT (
        clk, reset, D, Hold, Enable, syncrst : IN std_logic;
        Q : OUT std_logic
    );
END FF;

ARCHITECTURE Behaviour OF FF IS
BEGIN

    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
    Q <= '0';

ELSIF rising_edge(clk) THEN
    IF syncrst = '1' THEN --sync reset resets the ff value to 0
        Q <= '0';

    ELSIF Hold = '0' THEN --if hold is 1, then the value of the ff remain the same or frozen
        IF Enable = '1' THEN
            Q <= D; --otherwise if enable is 1 then output is D
        END IF;
		END IF;
	END IF;
    END PROCESS;

END Behaviour;