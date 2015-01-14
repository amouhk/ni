----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:50:53 06/04/2014 
-- Design Name: 
-- Module Name:    MEM_RAM - Behavioral 
-- Project Name:   AAA Face Detect
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.math_real.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MEM_RAM is
    generic (MEM_SIZE : integer);
    Port ( 
        CLK : in  STD_LOGIC;
        RESET : in  STD_LOGIC;
        addr : in  STD_LOGIC_VECTOR (31 downto 0);
        din : in  STD_LOGIC_VECTOR (31 downto 0);
        dout : out  STD_LOGIC_VECTOR (31 downto 0);
        we : in  STD_LOGIC;
        re : in  STD_LOGIC;
        
        -- 2ème port
        addr_B : in  STD_LOGIC_VECTOR (31 downto 0);
        din_B : in  STD_LOGIC_VECTOR (31 downto 0);
        dout_B : out  STD_LOGIC_VECTOR (31 downto 0);
        we_B : in  STD_LOGIC;
        re_B : in  STD_LOGIC
			  );
end MEM_RAM;

architecture Behavioral of MEM_RAM is

	type   type_mem_im is array(0 to MEM_SIZE) of std_logic_vector(7 downto 0);
   signal mem_im : type_mem_im;

begin
	process_mem_im : process(CLK, RESET)
    begin

        if RESET = '1' then
            for i in 0 to MEM_SIZE loop
                mem_im(i) <= X"00";
            end loop;
        else
            if CLK'event and CLK = '1' then
                -- écriture
                if we = '1' then 
                    mem_im(conv_integer(addr))     <= din(31 downto 24);
                    mem_im(conv_integer(addr + 1)) <= din(23 downto 16);
                    mem_im(conv_integer(addr + 2)) <= din(15 downto 8);
                    mem_im(conv_integer(addr + 3)) <= din(7 downto 0);
                end if;
                
                -- Lecture
                if re = '1' then 
                    dout(31 downto 24) <= mem_im(conv_integer(addr));
                    dout(23 downto 16) <= mem_im(conv_integer(addr + 1));
                    dout(15 downto 8)  <= mem_im(conv_integer(addr + 2));
                    dout(7 downto 0)   <= mem_im(conv_integer(addr + 3));
                end if;
                
                
                --2ème port
                -- écriture
                if we_B = '1' then 
                    mem_im(conv_integer(addr_B))     <= din_B(31 downto 24);
                    mem_im(conv_integer(addr_B + 1)) <= din_B(23 downto 16);
                    mem_im(conv_integer(addr_B + 2)) <= din_B(15 downto 8);
                    mem_im(conv_integer(addr_B + 3)) <= din_B(7 downto 0);
                end if;
                
                -- Lecture
                if re_B = '1' then 
                    dout_B(31 downto 24) <= mem_im(conv_integer(addr_B));
                    dout_B(23 downto 16) <= mem_im(conv_integer(addr_B + 1));
                    dout_B(15 downto 8)  <= mem_im(conv_integer(addr_B + 2));
                    dout_B(7 downto 0)   <= mem_im(conv_integer(addr_B + 3));
                end if;
            end if;	
        end if;
    end process;

end Behavioral;
