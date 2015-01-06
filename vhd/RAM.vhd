----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.12.2014 20:47:09
-- Design Name: 
-- Module Name: RAM - Behavioral
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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RAM is
    generic (MEM_SIZE : integer);
    Port ( CLK : in STD_LOGIC;
           RESET : in STD_LOGIC;
           
           wea   : in STD_LOGIC;
           rea   : in STD_LOGIC;
           addra : in STD_LOGIC_VECTOR (31 downto 0);
           dia   : in STD_LOGIC_VECTOR (31 downto 0);
           doa   : out STD_LOGIC_VECTOR (31 downto 0);
                      
           web   : in STD_LOGIC;
           reb   : in STD_LOGIC;
           addrb : in STD_LOGIC_VECTOR (31 downto 0);
           dib   : in STD_LOGIC_VECTOR (31 downto 0);
           dob   : out STD_LOGIC_VECTOR (31 downto 0)
          );
    end RAM;

architecture Behavioral of RAM is

    type type_mem_im is array(0 to MEM_SIZE) of std_logic_vector(7 downto 0);
    signal mem_im : type_mem_im;
    
begin
 
process_mem_im: process(CLK, RESET)
begin
    if RESET = '1' then
        for i in 0 to MEM_SIZE loop
            mem_im(i) <= X"00";
        end loop;
    else
        if CLK'event and CLK = '0' then
        -- écriture
            if wea = '1' then
                mem_im(conv_integer(addra))     <= dia(31 downto 24);
                mem_im(conv_integer(addra + 1)) <= dia(23 downto 16);
                mem_im(conv_integer(addra + 2)) <= dia(15 downto 8);
                mem_im(conv_integer(addra + 3)) <= dia(7 downto 0);
            end if;
        -- Lecture
            if rea = '1' then
                doa(31 downto 24) <= mem_im(conv_integer(addra));
                doa(23 downto 16) <= mem_im(conv_integer(addra + 1));
                doa(15 downto 8)  <= mem_im(conv_integer(addra + 2));
                doa(7 downto 0)   <= mem_im(conv_integer(addra + 3));
            end if;
        --2ème port
        -- écriture
            if web = '1' then
                mem_im(conv_integer(addrb))     <= dib(31 downto 24);
                mem_im(conv_integer(addrb + 1)) <= dib(23 downto 16);
                mem_im(conv_integer(addrb + 2)) <= dib(15 downto 8);
                mem_im(conv_integer(addrb + 3)) <= dib(7 downto 0);
            end if;
        -- Lecture
            if reb = '1' then
                dob(31 downto 24) <= mem_im(conv_integer(addrb));
                dob(23 downto 16) <= mem_im(conv_integer(addrb + 1));
                dob(15 downto 8)  <= mem_im(conv_integer(addrb + 2));
                dob(7 downto 0)   <= mem_im(conv_integer(addrb + 3));
            end if;
        end if;
    end if;
    end process;


end Behavioral;
