----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.12.2014 09:27:42
-- Design Name: 
-- Module Name: bench_ni - Behavioral
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bench_rx is
end bench_rx;

architecture Behavioral of bench_rx is
    component rx
        port (
            CLK             : in  std_logic;
            RESET           : in std_logic;
            --ni_tx_data
            S_NOC_READY     : in std_logic;
            S_NOC_VALID     : out std_logic;
            S_NOC_DATA      : in std_logic_vector(31 downto 0);
            S_NOC_WE        : in std_logic; -- indique le debut et la fin d'une transaction
            S_NOC_END_MSG   : in std_logic;
            S_NOC_BEG_MSG   : in std_logic;

            --irq to uC
            M_irq           : out std_logic;
            --local ram's signals
            M_IP_WE         : out std_logic;
            M_IP_RE         : out std_logic;
            M_IP_ADDR       : out std_logic_vector(31 downto 0);
            M_IP_DATA       : out std_logic_vector(31 downto 0)
        );
    end component;
    
    component RAM
        generic( MEM_SIZE : integer := 2000 );
        Port ( 
            CLK : in STD_LOGIC;
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
        
    end component;
    
    signal CLK     :   std_logic := '0';
    signal RESET   :  std_logic;
    
    
    
    --ni_tx_data
    signal S_NOC_READY      :  std_logic := '0';
    signal S_NOC_VALID      :  std_logic;
    signal S_NOC_DATA       :  std_logic_vector(31 downto 0) := (others => 'X');
    signal S_NOC_WE         :  std_logic := '0'; -- indique le debut et la fin d'une transaction
    signal S_NOC_END_MSG    :  std_logic := '0';
    signal S_NOC_BEG_MSG    :  std_logic := '0';
    --irq to uC
    signal M_irq            :  std_logic;
    --local ram's signals
    signal M_IP_WE   :  std_logic ;
    signal M_IP_RE   :  std_logic;
    signal M_IP_ADDR :  std_logic_vector(31 downto 0);
    signal M_IP_DATA :  std_logic_vector(31 downto 0);
    
    signal RE   :  std_logic;
    signal ADDR :  std_logic_vector(31 downto 0);
    signal DATA :  std_logic_vector(31 downto 0);
        
    constant clk_period : time := 5 ns;
    
    
begin
u_ram_600: RAM
    generic map (MEM_SIZE   => 2000)
    port map(
        CLK   => CLK, 
        RESET => RESET,
        
        wea   => M_IP_WE,
        rea   => M_IP_RE,
        addra => M_IP_ADDR,
        dia   => M_IP_DATA,
        doa   => open,
        
        web   => '0',
        reb   => RE,
        addrb => ADDR,
        dib   => (others => '0'),
        dob   => DATA
        
    );

u_rx: rx
    port map (
        CLK => CLK,
        RESET => RESET,
        --ni_tx_data
        S_NOC_READY => S_NOC_READY,
        S_NOC_VALID  => S_NOC_VALID,
        S_NOC_DATA => S_NOC_DATA,
        S_NOC_WE  => S_NOC_WE,
        S_NOC_END_MSG => S_NOC_END_MSG,
        S_NOC_BEG_MSG => S_NOC_BEG_MSG,
        --irq to uC
        M_irq  => M_irq,
        --local ram's signals
        M_IP_WE   =>  M_IP_WE,
        M_IP_RE  => M_IP_RE,
        M_IP_ADDR  => M_IP_ADDR,
        M_IP_DATA  => M_IP_DATA
    
    );

    CLK <= not(CLK) after clk_period;
    
    RESET <= '0', '1' after 3*clk_period , '0' after 7*clk_period;

--    S_NOC_READY <= '0', '1' after 15*clk_period , '0' after 19*clk_period, '1' after 89*clk_period, '0' after 93*clk_period;
p_ready: process
begin
    wait for 15*clk_period;
    S_NOC_READY <= '1';
    wait for 4*clk_period;
    S_NOC_READY <= '0';
    wait for 55*clk_period;
end process;
    
p_test: process 
begin 
    --wait for 21*clk_period;
    for j in 1 to 8 loop
            S_NOC_BEG_MSG <= '1';
        wait until S_NOC_VALID = '1';   
        for i in 1 to 16 loop
              S_NOC_BEG_MSG <= '1';
--            if j=1 then
--                S_NOC_BEG_MSG <= '1';      
--            else
--                S_NOC_BEG_MSG <= '0';
--            end if;
            if i=16 then
                S_NOC_END_MSG <= '1';
            else
                S_NOC_END_MSG <= '0';      
            end if;
            
            S_NOC_DATA <= conv_std_logic_vector(i, 32);
            S_NOC_WE <= '1';
            wait for 2*clk_period;
        end loop;
        
        S_NOC_WE <= '0';
        
        wait for 42*clk_period;
        
    end loop;
end process;

-- pragma translate_off
--lecture_memory: process
--    variable L: line;
--    file SORTIES : text open write_mode is "sortie.dat";
--	variable A: integer;	 -- variables à lire
--begin
--    wait for 90*clk_period;
--    for i in 0 to 576 loop
--        RE      <= '1';
--        ADDR    <= conv_std_logic_vector(i, 32);
--        wait for 2*clk_period;
--        RE <= '0';
--        A := to_integer(ieee.numeric_std.unsigned(DATA));
--        write (L, A);
--        writeline(SORTIES, L);
--    end loop;

--end process;
	-- pragma translate_on

    
end Behavioral;
