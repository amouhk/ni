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

            --irq to uC
            M_irq           : out std_logic;
            --local ram's signals
            M_IP_WE         : out std_logic;
            M_IP_RE         : out std_logic;
            M_IP_ADDR       : out std_logic_vector(31 downto 0);
            M_IP_DATA       : out std_logic_vector(31 downto 0);
            M_IP_RB         : in  std_logic_vector(31 downto 0)
        );
    end component;
    
    component MEM_RAM
        generic( MEM_SIZE : integer := 700 );
        Port ( 
            CLK     : in  STD_LOGIC;
            RESET   : in  STD_LOGIC;
            -- 1er port A
            addr    : in  STD_LOGIC_VECTOR (31 downto 0);
            din     : in  STD_LOGIC_VECTOR (31 downto 0);
            dout    : out  STD_LOGIC_VECTOR (31 downto 0);
            we      : in  STD_LOGIC;
            re      : in  STD_LOGIC;
            --2eme port B
            addr_B  : in  STD_LOGIC_VECTOR (31 downto 0);
            din_B   : in  STD_LOGIC_VECTOR (31 downto 0);
            dout_B  : out  STD_LOGIC_VECTOR (31 downto 0);
            we_B    : in  STD_LOGIC;
            re_B    : in  STD_LOGIC
        );
        
    end component;
    
    signal CLK     :  std_logic := '0';
    signal RESET   :  std_logic;
    
    
    
    --ni_tx_data
    signal S_NOC_READY      :  std_logic := '0';
    signal S_NOC_VALID      :  std_logic;
    signal S_NOC_DATA       :  std_logic_vector(31 downto 0) := (others => 'X');
    signal S_NOC_WE         :  std_logic := '0'; -- indique le debut et la fin d'une transaction
    signal S_NOC_END_MSG    :  std_logic := '0';
    --irq to uC
    signal M_irq        :  std_logic;
    --local ram's signals
    signal M_IP_WE      :  std_logic ;
    signal M_IP_RE      :  std_logic;
    signal M_IP_ADDR    :  std_logic_vector(31 downto 0);
    signal M_IP_DATA    :  std_logic_vector(31 downto 0):= (others => '0');
    signal M_IP_RB      :  std_logic_vector(31 downto 0):= (others => '0');
    
    signal re_fill      :  std_logic:= '0';
    signal we_fill      :  std_logic:= '0';
    signal addr_fill    :  std_logic_vector(31 downto 0):= (others => '0');
    signal data_fill    :  std_logic_vector(31 downto 0);
    signal data_out     :  std_logic_vector(31 downto 0);
    
    signal end_fill_ram : std_logic := '0';
        
    constant clk_period : time := 5 ns;
    
begin
u_ram: MEM_RAM
    generic map (MEM_SIZE => 700)
    port map(
        CLK     => CLK, 
        RESET   => RESET,
        --port 1
        we      => M_IP_WE,
        re      => M_IP_RE,
        addr    => M_IP_ADDR,
        din     => M_IP_DATA,
        dout    => M_IP_RB,
        --port 2
        we_B    => we_fill,
        re_B    => re_fill,
        addr_B  => addr_fill,
        din_B   => data_fill,
        dout_B  => data_out
        
    );

u_rx: rx
    port map (
        CLK         => CLK,
        RESET       => RESET,
        --ni_tx_data
        S_NOC_READY => S_NOC_READY,
        S_NOC_VALID => S_NOC_VALID,
        S_NOC_DATA  => S_NOC_DATA,
        S_NOC_WE    => S_NOC_WE,
        S_NOC_END_MSG => S_NOC_END_MSG,
        --irq to uC
        M_irq  => M_irq,
        --local ram's signals
        M_IP_WE     => M_IP_WE,
        M_IP_RE     => M_IP_RE,
        M_IP_ADDR   => M_IP_ADDR,
        M_IP_DATA   => M_IP_DATA,
        M_IP_RB     => M_IP_RB
    );

    CLK <= not(CLK) after clk_period;
    
    RESET <= '0', '1' after 3*clk_period , '0' after 7*clk_period;
    
    S_NOC_READY <= '0', '1' after 50*clk_period ,  '0' after 54*clk_period, 
                        '1' after 140*clk_period , '0' after 144*clk_period,
                        '1' after 230*clk_period , '0' after 234*clk_period,
                        '1' after 320*clk_period , '0' after 324*clk_period,
                        '1' after 410*clk_period , '0' after 414*clk_period,
                        '1' after 500*clk_period , '0' after 504*clk_period,
                        '1' after 590*clk_period , '0' after 594*clk_period,
                        '1' after 680*clk_period , '0' after 684*clk_period,
                        '1' after 770*clk_period , '0' after 774*clk_period;
------------------------------------------------------------------------
-- Processus qui remplit la memoire
fill_ram : process
begin
    wait for 20*clk_period;
    -- On remplit le RB
    for i in 0 to 7 loop
        we_fill <= '1';
        data_fill <= conv_std_logic_vector(128 + (64 * i), 32);
        addr_fill <= conv_std_logic_vector(8*i + 4, 32);
        wait for clk_period;
        we_fill <= '0';
        wait for clk_period;
    end loop;
    wait for 4*clk_period;
    end_fill_ram <= '1';
    wait on RESET;
end process;
-------------------------------------------------------------------------
--Process de simulation du NI_TX
--p_ready: process
--begin
--    --for i in 1 to 2 loop
--        wait until end_fill_ram = '1';
--        wait for 10*clk_period;
--        S_NOC_READY <= '1';
--        wait for 4*clk_period;
--        S_NOC_READY <= '0';
--        wait for 76*clk_period;
--   --end loop;
----    wait on RESET;
--end process;

-----------------------------------------------------------------------
--Process de simulation du NI_TX
--le message se trouve dans une seule barette de 16 mots 
short_msg_test: process 
begin 
    wait until end_fill_ram = '1';
    for j in 1 to 9 loop
        wait until S_NOC_VALID = '1';   
        for i in 1 to 16 loop
            S_NOC_DATA <= conv_std_logic_vector(i, 32);
            S_NOC_WE <= '1';
            wait for 2*clk_period;
        end loop;
        
        S_NOC_WE <= '0';
        wait for 42*clk_period;
    end loop;
end process;
-----------------------------------------------------------------------
-----------------------------------------------------------------------
--Process de simulation du NI_TX 
--le message se trouve dans plusieurs barette de 16 mots  
--big_msg_test: process 
--begin 
--    wait until end_fill_ram = '1';
--    for j in 1 to 9 loop
--        wait until S_NOC_VALID = '1';   
--        for i in 1 to 16 loop
--            S_NOC_DATA <= conv_std_logic_vector(i, 32);
--            S_NOC_WE <= '1';
--            wait for 2*clk_period;
--        end loop;
        
--        S_NOC_WE <= '0';
--        wait for 42*clk_period;
--    end loop;
--end process;
-----------------------------------------------------------------------
end Behavioral;
