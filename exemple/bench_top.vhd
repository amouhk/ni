--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:52:03 06/09/2014
-- Design Name:   
-- Module Name:   C:/Users/kamouh/Desktop/Projet/NewFSM/testfsm/bench_top.vhd
-- Project Name:  testfsm
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: top_video
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY bench_top IS
END bench_top;
 
ARCHITECTURE behavior OF bench_top IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top_video
    PORT(
        CLK       : in  STD_LOGIC;
		  Reset     : in  STD_LOGIC;
		  Vsync     : in  STD_LOGIC;
		  Href      : in  STD_LOGIC;
		  Data_in   : in  STD_LOGIC_VECTOR (7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal din : std_logic_vector(7 downto 0) := (others => '0');
   signal href : std_logic := '0';
   signal vsync : std_logic := '0';

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top_video PORT MAP (
          clk => clk,
          reset => rst,
          data_in => din,
          href => href,
          vsync => vsync
        );

   -- Clock process definitions
   -- définition des signaux répétitifes
		CLK <= not(CLK) after 5 ns; -- periode 10 ns
		Rst <= '1', '0' after 50 ns;
		Vsync <= '0', '1' after 100 ns, '0' after 150 ns, '1' after 100 ms;
		
--	 process Href
		proc_href : process
		
		begin
			Href <= '0' ;
			wait for 200 ns;
			for i in 1 to 1944 loop
				Href <= '1' ;
				wait for 25920 ns;
				Href <= '0' ;
				wait for 50 ns;
			end loop;
			assert (1=3) report "erreur classique" severity error;
		end process;
		
		
	--  Test Bench Statements
     tb : PROCESS
     BEGIN
			wait for 200 ns;
			for i in 1 to 972 loop
				for j in 1 to 648 loop  -- première ligne
					din <= "00001010";  -- 10
					wait for 10ns;
					din <= "00011110";  -- 30
					wait for 10ns;
					din <= "01100100";  -- 100
					wait for 10ns;
					din <= "00000000";  -- 0
					wait for 10ns;
				end loop;
				wait for 50 ns;

				
				for j in 1 to 648 loop  -- deuxième ligne
					din <= "00101000";  -- 40
					wait for 10ns;
					din <= "00101000";  -- 40
					wait for 10ns;
					din <= "00001010";  -- 10
					wait for 10ns;
					din <= "01011010";  -- 90
					wait for 10ns;
				end loop;
				
				wait for 50 ns;
			end loop;

			wait; -- will wait forever
     END PROCESS tb;


END;