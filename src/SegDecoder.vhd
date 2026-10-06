--Sumair and Jack
LIBRARY IEEE;
use IEEE.std_logic_1164.all;
--same segdecoder from other labs minus the HEX outputs
ENTITY SegDecoder IS
	PORT ( D : IN std_logic_vector(3 downto 0);
			 Y : OUT std_logic_vector(6 downto 0) );
END SegDecoder;

ARCHITECTURE LogicFunction OF SegDecoder IS
BEGIN
	WITH D SELECT
		Y <= "1000000" WHEN "0000",
			  "1111001" WHEN "0001",
			  "0100100" WHEN "0010",
			  "0110000" WHEN "0011",
			  "0011001" WHEN "0100",
			  "0010010" WHEN "0101",
			  "0000010" WHEN "0110",
			  "1111000" WHEN "0111",
			  "0000000" WHEN "1000",
			  "0010000" WHEN "1001",
			  "1000000" WHEN OTHERS;
END LogicFunction;