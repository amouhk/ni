----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.01.2015 16:12:25
-- Design Name: 
-- Module Name: define_constants - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.NUMERIC_STD.ALL;

package define is

--Declare constants
	
	--constant BUFFER_SIZE	: unsigned := 4*16; --max 256
	constant DESC_SIZE	    : std_logic_vector(31 downto 0) := (3=> '1', others => '0');
    constant MEM_BASE_ADDR    : std_logic_vector(31 downto 0) := (others=> '0');
	--Addresse du debut des donnes
	--constant DATA_BASE_ADDR	: std_logic_vector(31 downto 0) := conv_std_logic_vector(unsigned(MEM_BASE_ADDR) + 64, 32) ; -- 32 = 4*(2*nombre de buffer)
	


end define;