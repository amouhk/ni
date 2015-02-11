----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.12.2014 20:18:03
-- Design Name: 
-- Module Name: bench_fifo - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bench_fifo is
end bench_fifo;

architecture Behavioral of bench_fifo is
component fifo
       PORT (
        clk : IN STD_LOGIC;
        srst : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC
      );
    end component;
    
    --signaux internes
        signal clk   : std_logic := '0';
        signal rst   : std_logic := '0';
        signal din   : std_logic_vector(31 downto 0):= (others => 'X');
        signal dout  : std_logic_vector(31 downto 0);
        signal wr_en : std_logic := '0';
        signal rd_en : std_logic := '0';
        signal full  : std_logic;
        signal empty : std_logic;
        
        constant clk_period : time := 5 ns;
begin
    dut: fifo 
    port map(
        clk  => clk,
        srst  => rst,
        din  => din,
        dout => dout,
        wr_en => wr_en,
        rd_en => rd_en,
        full  => full,
        empty => empty    
         );
    
    clk <= not(clk) after clk_period;
    rst <= '0', '1' after 3*clk_period , '0' after 7*clk_period;
  

p_test: process 
begin 
    wait for 13*clk_period;
    for i in 1 to 17 loop 
        din <= conv_std_logic_vector(i, 32);
        wr_en <= '1';
        wait for 2*clk_period;
    end loop;
    
    wr_en <= '0';
    wait for 2*clk_period;
    
    rd_en <= '1';

    
end process;

end Behavioral;
