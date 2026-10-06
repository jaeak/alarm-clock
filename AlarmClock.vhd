LIBRARY IEEE;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all; 

--Top level entity. Ports are the keys, switches, clocks, 7 segment displays, and LEDs on the FPGA
ENTITY AlarmClock IS
	PORT ( KEY : IN std_logic_vector (3 downto 0);
			 SW : IN std_logic_vector (1 downto 0);
			 CLOCK_50, CLOCK2_50 : IN std_logic;
			 HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : OUT std_logic_vector (6 downto 0);
			 LEDR : OUT std_logic_vector (9 downto 0)
			 );
END AlarmClock;


ARCHITECTURE Behaviour OF AlarmClock IS

--3 states, either the clock is running, being set, or the alarm is being set
TYPE state_type IS(running, set, alarmset);
SIGNAL state : state_type;

--all the components
--seg decoder to convert 4 bit numbers to decimal numbers able to be displayed on the 7-segment
COMPONENT SegDecoder  
	PORT ( D : IN std_logic_vector(3 downto 0);
			 Y : OUT std_logic_vector(6 downto 0) );
END COMPONENT;

--PulseGenerator
COMPONENT PulseGenerate
    PORT (
        clock, reset, button : IN std_logic;
        pulse : OUT std_logic
    );
END COMPONENT;

--running clock
COMPONENT RunningClock
	PORT ( clock, reset, holdsec, holdmin, holdhr, incsec, incmin, inchr : IN std_logic;
			 Seg0, Seg1, Seg2, Seg3, Seg4, Seg5 : OUT std_logic_vector (3 downto 0)
			 );
END COMPONENT;

--set time
COMPONENT SetTime 
	PORT ( clock, reset, increment, toggle : IN std_logic;
			 sechold, minhold, hrhold, incsec, incmin, inchr : OUT std_logic
			 );
END COMPONENT;

--alarm
COMPONENT Alarm
    PORT (
		  Q0, Q1, Q2, Q3, Q4, Q5 : IN std_logic_vector (3 downto 0);
        clock, reset, increment, toggle, confirm, stop : IN  std_logic;
        Seg0, Seg1, Seg2, Seg3, Seg4, Seg5 : OUT std_logic_vector(3 DOWNTO 0);
		  alarmActive, armed : OUT std_logic
    );
END COMPONENT;

--prescale clock (this will be the slow clock which readings will be clean pulses)
COMPONENT PreScale
	GENERIC (dataw : integer := 25);
	PORT (InClock : IN std_logic;
			OutClock : OUT std_logic
			);
END COMPONENT;

--slow clock signal
SIGNAL clk : std_logic;

--final output 4 bit signals that will be displayed on the 7 segmens
SIGNAL sec0, sec1, min0, min1, hr0, hr1 : std_logic_vector (3 downto 0);

--these are the 4 bit outputs specific to the running clock or set time
SIGNAL Rsec0, Rsec1, Rmin0, Rmin1, Rhr0, Rhr1 : std_logic_vector (3 downto 0);

--these are 4 bit outputs specific to the alarm
SIGNAL Asec0, Asec1, Amin0, Amin1, Ahr0, Ahr1 : std_logic_vector (3 downto 0);


--these are both the hold and increment signals that will be input into running clock to decide 
--which values increment, and which values are held depending on the state of the clock (Whether you are setting, or the clock is running.)
--for the increment signals, they will simpily be the enable of the runningclock BCD instantiation
--which is just the enable pin of each flip flop, so we have control over which values increment while
--keeping a common clock throughout the system
--The hold signals just tell those flipflops to "do nothing"
SIGNAL incrsecIN, incrminIN, incrhrIN : std_logic;
SIGNAL hldsecIN, hldminIN, hldhrIN : std_logic;

--these are both the hold and increment signals that will be output from set time, and decide
--for running clocks instantiation, which values will increment (enable FF), and which values will be held
SIGNAL incrsecOUT, incrminOUT, incrhrOUT : std_logic;
SIGNAL hldsecOUT, hldminOUT, hldhrOUT : std_logic;

--rollover signals for hours and minutes. hours rollover when minutes = seconds = 59
--minutes rollover when seconds = 59
SIGNAL minrollover, hrrollover : std_logic;

--signals for each of the buttons. these will be outputs of pulse generator to generate the clean button signals
SIGNAL modebutton, incrementbutton, togglebutton : std_logic;

--these signals are to seperate toggle and increment between alarm and set time, so if you are setting the time,
--you dont accidentally also increment the alarm, and vice versa. These will be assigned to the clean button readings
--depending on state.
SIGNAL timeincrement, timetoggle, alarmincrement, alarmtoggle : std_logic;

--clock pulse is used to pulse the slow clock so that only one clock signal is detected on the fast clock cycle
--clock pulse allows us to use one clock for the whole system (since originally, I wanted to use the slow
--clock for the below running clock instantiation, but now its CLOCK_50 like the rest of the system). Instead
--of using slow clock for the clock of runningclock, I use it as the enable (named incrsecIN, incrminIN, or incrhrIN)
--alarm signal is used to signal if the alarm is triggered
--alarm confirm is used to signal if alarm has been activated at a given time
--alarmstop stops or cancels the alarm thats already been set
--alarm armed signals if the alarm has been armed or not 
SIGNAL ClockPulse, alarmSignal, alarmconfirm, alarmstop, alarmArmed : std_logic;

BEGIN

--slow clock for when the clock runs 
ClkScale : PreScale PORT MAP(InClock => CLOCK2_50, OutClock => clk);

--minutes rollover (or increment) when seconds is 59 when running
minrollover <= (Rsec0(3) AND Rsec0(0)) AND (Rsec1(2) AND Rsec1(0));

--hours rollover (or increment) when minutes is 59 and seconds is also 59
hrrollover <= minrollover AND ((Rmin0(3) AND Rmin0(0)) AND (Rmin1(2) AND Rmin1(0)));

	PROCESS(CLOCK_50, KEY(3)) --the main fsm function sensitive to the fast clock and main hard reset
		BEGIN
			IF KEY(3) = '0' THEN 
				state <= running; --default to running state
			ELSIF CLOCK_50'EVENT AND CLOCK_50 = '1' THEN --on the fast clocks rising edge
					IF SW = "00" THEN
						state <= running; --if the switch is at 00 then the clock runs as normal and is in running state
					ELSIF SW = "01" THEN
						state <= set; --if the switch is at 01 then the clock is being set and is in set state
					ELSIF SW = "11" THEN
						state <= alarmset; --if the switch is at 11 then the clock is in alarm set mode, and the alarm is being set
					ELSE
						state <= running; --if switch is at 10, then default to running.
				END IF;
			END IF;
		END PROCESS;

sec0 <= Asec0 WHEN state = alarmset ELSE Rsec0; --the displays for each value for time will display the alarm that is set
sec1 <= Asec1 WHEN state = alarmset ELSE Rsec1; --only when the state is to set the alarm, otherwise the displayed time will
min0 <= Amin0 WHEN state = alarmset ELSE Rmin0; --be of the running clock which shares a display when you set the time as well
min1 <= Amin1 WHEN state = alarmset ELSE Rmin1; --since the clock runs starting from whatever time you set
hr0 <= Ahr0 WHEN state = alarmset ELSE Rhr0;
hr1 <= Ahr1 WHEN state = alarmset ELSE Rhr1;

LEDR(0) <= '1' WHEN state = running ELSE '0'; --running state is shown by the first led, otherwise that LED is off
LEDR(1) <= '1' WHEN state = set ELSE '0'; --set state is shown by second led
LEDR(2) <= '1' WHEN state = alarmset ELSE '0'; --alarm set is shown by third
LEDR(3) <= alarmArmed; --led 3 will show whether the alarm is armed or not
LEDR(9 DOWNTO 4) <= (OTHERS => alarmSignal); --if the alarm is triggered, then all the other LEDs will light up

timeIncrement <= incrementbutton WHEN state = set ELSE '0'; --set time increment, and toggle will only be set to the toggle and increment button
timeToggle <= togglebutton WHEN state = set ELSE '0'; --if the state is in set time mode

alarmincrement <= incrementbutton WHEN state = alarmset ELSE '0'; --alarm increment and toggle will only be set to toggle and increment button
alarmtoggle <= togglebutton WHEN state = alarmset ELSE '0'; --if the state is in set alarm mode

alarmconfirm <= modebutton WHEN state = alarmset AND alarmSignal = '0' ELSE '0'; -- confirm alarm will be set to KEY(0)s clean output only when your in alarmset mode and the alarm isnt triggered

alarmstop <= modebutton WHEN alarmArmed = '1' ELSE '0'; --alarm can be stopped, or unarmed if alarm is already armed, or alarm is triggered

PROCESS(state, ClockPulse, minrollover, hrrollover, incrsecOUT, incrminOUT, incrhrOUT, hldsecOUT, hldminOUT, hldhrOUT)
BEGIN --process statement sensitive to all values that will be written in different cases
    CASE state IS --depends on state
        WHEN running => --if the state is in running
            incrsecIN <= ClockPulse; --increment seconds based on the clean slow clock (clean is needed as the slow clock will be
											--1 for multiple fast clock cycles. so instead, near the bottom we use pulseGenerator for slow clock
            incrminIN <= ClockPulse AND minrollover; --minutes will increment if the clock ticks, and seconds are at 59
            incrhrIN  <= ClockPulse AND hrrollover; --hours will increment if the clock ticks and minutes = seconds = 59
            hldsecIN <= '0'; --dont hold any of the values, as the clock is freely running
            hldminIN <= '0';
            hldhrIN  <= '0';
        WHEN set => --when in set mode
            incrsecIN <= incrsecOUT; --increment each value depending on the output of set time
            incrminIN <= incrminOUT;
            incrhrIN  <= incrhrOUT;
            hldsecIN <= hldsecOUT; --hold each value depending on the output of set time
            hldminIN <= hldminOUT;
            hldhrIN  <= hldhrOUT;
        WHEN alarmset => --when state is in alarmset mode
            incrsecIN <= ClockPulse; --run the main clock as normal (running clock)
				incrminIN <= ClockPulse AND minrollover;
				incrhrIN  <= ClockPulse AND hrrollover;
				hldsecIN <= '0';
				hldminIN <= '0';
				hldhrIN  <= '0';
    END CASE;
END PROCESS;

--Generate a pulse for the set/unset alarm key
ModeEdge : PulseGenerate PORT MAP(clock => CLOCK_50, reset => NOT KEY(3), button => KEY(0), pulse => modebutton);

--generate a pulse for the increment button for set time and set alarm
IncrementEdge : PulseGenerate PORT MAP(clock => CLOCK_50, reset => NOT KEY(3), button => KEY(1), pulse => incrementbutton);

--generate a pulse for the toggle button for the same thing
ToggleEdge : PulseGenerate PORT MAP(clock => CLOCK_50, reset => NOT KEY(3), button => KEY(2), pulse => togglebutton);

--generate a pulse for the slow clock (so values increment by one each time)
ClkPulse : PulseGenerate PORT MAP (clock  => CLOCK_50, reset  => NOT KEY(3), button => clk, pulse  => ClockPulse);
	

--port map set time. time increments when the clean KEY pulse is read from KEY(1) and only if it is in set time mode
--(which is when timeincrement will be set to KEY(1). same thing will timetoggle. Outputs will determine which values
--will be held and which values will be incremented depedning on the state of set time (are you setting hours, minutes, or seconds?)
TimeSetter : SetTime PORT MAP (clock => CLOCK_50, reset => KEY(3), increment => timeincrement, toggle => timetoggle,
										 sechold => hldsecOUT, minhold => hldminOUT, hrhold => hldhrOUT,
										 incsec => incrsecOUT, incmin => incrminOUT, inchr => incrhrOUT);

--running clock takes the increment and hold IN inputs, which change depending on state. if the state is running, then all 
--the hold inputs will go to 0, and increment seconds will increment on the slow clock, and increment hours, and minutes will also
--depend on slow clock alongside their respective rollover signals from above. outputs will be outputted to the running clock
--values
RunClock : RunningClock PORT MAP (clock => CLOCK_50, reset => NOT KEY(3), holdsec => hldsecIN, holdmin => hldminIN, holdhr => hldhrIN,
											 incsec => incrsecIN, incmin => incrminIN, inchr => incrhrIN,
											 Seg0 => Rsec0, Seg1 => Rsec1, Seg2 => Rmin0, Seg3 => Rmin1, Seg4 => Rhr0, Seg5 => Rhr1);

--the alarm clock will take the running clock values as input to compare to whichever alarm you set. increment and toggle
--depend on state, if state is in alarm set then alarmincrement and alarmtoggle will be KEY(1) and KEY(2) respectively, and
--alarm can be set that way. confirm will be confirmed using alarmconfirmed which is set to KEY(0) only when in alarmset mode
--and if alarm hasnt been set. stop is set to alarm stop which is also set to KEY(0) in any state and only when alarm has been set
--all of the 4 bit number outputs are set to their respective alarm values, which will only be displayed when in alarmset state
--outputs are alarmsignal, which signals if the alarm has been triggered, and alarmarmed, which signals if the alarm is armed (via LED(4))									 
AlarmFunction : Alarm PORT MAP (Q0 => Rsec0, Q1 => Rsec1, Q2 => Rmin0, Q3 => Rmin1, Q4 => Rhr0, Q5 => Rhr1, clock => CLOCK_50,
										  reset => NOT KEY(3), increment => alarmincrement, toggle => alarmtoggle, confirm => alarmconfirm,
										  stop => alarmstop, Seg0 => Asec0, Seg1 => Asec1, Seg2 => Amin0, Seg3 => Amin1, Seg4 => Ahr0,
										  Seg5 => Ahr1, alarmActive => alarmSignal, armed => alarmArmed);

Display0 : SegDecoder PORT MAP (D => sec0, Y => HEX0); --final outpus on 7 segments are either Alarmsets values
Display1 : SegDecoder PORT MAP (D => sec1, Y => HEX1); --or running clocks values depending on state.
Display2 : SegDecoder PORT MAP (D => min0, Y => HEX2); --the output under the main FSM process above assigns
Display3 : SegDecoder PORT MAP (D => min1, Y => HEX3); --alarms outputs to final output only when the state is alarmset
Display4 : SegDecoder PORT MAP (D => hr0, Y => HEX4);	--otherwise it will display only the running time outputs
Display5 : SegDecoder PORT MAP (D => hr1, Y => HEX5); --which start with an R

END Behaviour;