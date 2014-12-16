----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/10/2014 03:20:59 PM
-- Design Name: 
-- Module Name: bench_tx - Behavioral
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bench_tx is
end bench_tx;

architecture Behavioral of bench_tx is
    component tx port(
        CPU_addr     : in STD_LOGIC_VECTOR (31 downto 0);
        CPU_we       : in STD_LOGIC;
        rst          : in STD_LOGIC;
        clk          : in STD_LOGIC;
        RAM_DATA     : in STD_LOGIC_VECTOR (31 downto 0);
        RAM_WE       : out STD_LOGIC;
        RAM_RE       : out STD_LOGIC;
        RAM_ADDR     : out STD_LOGIC_VECTOR (31 downto 0)
    );
    end component;
    
    component MEM_RAM Port ( 
        CLK     : in  STD_LOGIC;
        RESET   : in  STD_LOGIC;
        addr    : in  STD_LOGIC_VECTOR (31 downto 0);
        din     : in  STD_LOGIC_VECTOR (31 downto 0);
        dout    : out  STD_LOGIC_VECTOR (31 downto 0);
        we      : in  STD_LOGIC;
        re      : in  STD_LOGIC;
        addr_B  : in  STD_LOGIC_VECTOR (31 downto 0);
        din_B   : in  STD_LOGIC_VECTOR (31 downto 0);
        dout_B  : out  STD_LOGIC_VECTOR (31 downto 0);
        we_B    : in  STD_LOGIC;
        re_B    : in  STD_LOGIC
    );
    end component;
    
    --signaux généré par le bench
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal CPU_addr     : std_logic_vector(31 downto 0) := (others => '0');
    signal CPU_we       : STD_LOGIC := '0';
    
    signal din_ram      : std_logic_vector(31 downto 0) := (others => '0');
    signal din_ram_B    : std_logic_vector(31 downto 0) := (others => '0');
    signal addr_ram_B   : std_logic_vector(31 downto 0) := (others => '0');
    signal data_ram_B   : std_logic_vector(31 downto 0) := (others => '0');
    signal re_ram_B     : std_logic := '0';
    signal we_ram_B     : std_logic := '0';

    -- jonction entre les composants
    signal addr_ram : std_logic_vector(31 downto 0);
    signal data_ram : std_logic_vector(31 downto 0);
    signal re_ram   : std_logic;
    signal we_ram   : std_logic;
    
    constant clk_demi_period : time := 5 ns;
    
    
begin
    u1 : tx port map(
        CPU_addr    => CPU_addr,
        CPU_we      => CPU_we,
        rst         => rst,
        clk         => clk,
        RAM_DATA    => data_ram,
        RAM_WE      => we_ram,
        RAM_RE      => re_ram,
        RAM_ADDR    => addr_ram
    );
    
    u2 : MEM_RAM port map(
        CLK     => clk,
        RESET   => rst,
        addr    => addr_ram,
        din     => din_ram,
        dout    => data_ram,
        we      => we_ram,
        re      => re_ram,
        addr_B  => addr_ram_B,
        din_B   => din_ram_B,
        dout_B  => data_ram_B,
        we_B    => we_ram_B,
        re_B    => re_ram_B
    );

    CLK <= not(CLK) after clk_demi_period; -- periode 10 ns
    Rst <= '1', '0' after 50 ns;

    fill_ram : process
    begin
        wait for 100 ns;
        -- On remplit le RB
        for i in 1 to 8 loop
            we_ram_B <= '1';
            din_ram_B <= X"00100010"; -- size = size_max = 16, eom = '0'
            addr_ram_B <= conv_std_logic_vector(2*i - 1,32);
            wait for 10 ns;
            we_ram_B <= '0';
            wait for 10 ns;
            we_ram_B <= '1';
            din_ram_B <= conv_std_logic_vector(512 + (40 * (i-1)), 32);
            addr_ram_B <= conv_std_logic_vector(2*i,32);
        end loop;
    end process;
    
    
end Behavioral;
