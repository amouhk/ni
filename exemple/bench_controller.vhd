--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:52:46 06/04/2014
-- Design Name:   
-- Module Name:   /user/3/.base/habchip/home/FaceDetect/A3/video/camera_parrallele/Luminance/bench_controller.vhd
-- Project Name:  Luminance
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: controller
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
 
ENTITY bench_controller IS
END bench_controller;
 
ARCHITECTURE behavior OF bench_controller IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT controller
    PORT(
         CLK     : IN  std_logic;
         Reset   : IN  std_logic;
         Vsync   : IN  std_logic;
         Href    : IN  std_logic;
         Data_in : IN  std_logic_vector(7 downto 0);
         PWDN    : OUT  std_logic;
         Data_out: OUT  std_logic_vector(7 downto 0);
         we      : OUT  std_logic;
         addr    : OUT  std_logic_vector(20 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK     : std_logic := '0';
   signal Reset   : std_logic;
   signal Vsync   : std_logic;
   signal Href    : std_logic;
   signal Data_in : std_logic_vector(7 downto 0) := "11000000";

 	--Outputs
   signal PWDN : std_logic;
   signal Data_out : std_logic_vector(7 downto 0);
   signal we : std_logic;
   signal addr : std_logic_vector(20 downto 0);



 
BEGIN
 
	 -- Instantiate the Unit Under Test (UUT)
   u1: controller PORT MAP (
          CLK      => CLK,
          Reset    => Reset,
          Vsync    => Vsync,
          Href     => Href,
          Data_in  => Data_in,
          PWDN     => PWDN,
          Data_out => Data_out,
          we       => we,
          addr     => addr
        );
		  
		  
	-- définition des signaux répétitifes
		CLK <= not(CLK) after 5 ns; -- periode 10 ns
		Reset <= '1', '0' after 50 ns;
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
					Data_in <= "00001010";  -- 10
					wait for 10ns;
					Data_in <= "00011110";  -- 30
					wait for 10ns;
					Data_in <= "01100100";  -- 100
					wait for 10ns;
					Data_in <= "00000000";  -- 0
					wait for 10ns;
				end loop;
				wait for 50 ns;

				
				for j in 1 to 648 loop  -- deuxième ligne
					Data_in <= "00101000";  -- 40
					wait for 10ns;
					Data_in <= "00101000";  -- 40
					wait for 10ns;
					Data_in <= "00001010";  -- 10
					wait for 10ns;
					Data_in <= "01011010";  -- 90
					wait for 10ns;
				end loop;
				
				wait for 50 ns;
			end loop;

			wait; -- will wait forever
     END PROCESS tb;


 
END;
