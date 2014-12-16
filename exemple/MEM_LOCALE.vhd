----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:50:53 06/04/2014 
-- Design Name: 
-- Module Name:    MEM_IMAGE - Behavioral 
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

entity MEM_IMAGE is
    Port ( CLK : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
           addra : in  STD_LOGIC_VECTOR (10 downto 0);
           dia : in  STD_LOGIC_VECTOR (7 downto 0);
           doa : out  STD_LOGIC_VECTOR (7 downto 0);
           wea : in  STD_LOGIC;
           rea : in  STD_LOGIC;
			  
			  addrb : in  STD_LOGIC_VECTOR (10 downto 0);
           dib : in  STD_LOGIC_VECTOR (7 downto 0);
           dob : out  STD_LOGIC_VECTOR (7 downto 0);
           web : in  STD_LOGIC;
           reb : in  STD_LOGIC
			  );
end MEM_IMAGE;

architecture Behavioral of MEM_IMAGE is

	type   type_mem_im is array(0 to 1295) of std_logic_vector(7 downto 0);
   signal mem_im : type_mem_im;

begin
	process_mem_im : process(CLK, RESET)
    begin

        if RESET = '1' then
            for i in 0 to 1295 loop
                mem_im(i) <= X"00";
            end loop;
        else
				if CLK'event and CLK = '0' then
					--PortA
					if wea = '1' then 
						mem_im(conv_integer(addra)) <= dia;
					end if;
					
					if rea = '1' then 
						doa <= mem_im(conv_integer(addra));
					end if;
					
					-- PortB
					if web = '1' then 
						mem_im(conv_integer(addrb)) <= dib;
					end if;
				
					if reb = '1' then 
						dob <= mem_im(conv_integer(addrb));
					end if;
						
				end if;	
        end if;
    end process;

end Behavioral;
