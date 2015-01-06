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
        RAM_ADDR     : out STD_LOGIC_VECTOR (31 downto 0);
        NI_ack       : in STD_LOGIC;
        NI_ready     : out STD_LOGIC;
        NI_data      : out STD_LOGIC_VECTOR (31 downto 0);
        NI_we        : out STD_LOGIC
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
    
    --signaux genere par le bench
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
    signal ram_fill     : std_logic := '0';

    -- jonction entre les composants
    signal addr_ram : std_logic_vector(31 downto 0);
    signal data_ram : std_logic_vector(31 downto 0);
    signal re_ram   : std_logic;
    signal we_ram   : std_logic;
    
    -- signaux inutils qui simuleront le NI_rx
    signal ack_ni       : STD_LOGIC := '0';
    signal ready_ni     : STD_LOGIC;
    signal data_ni      : STD_LOGIC_VECTOR (31 downto 0);
    signal we_ni        : STD_LOGIC;
    
    constant clk_demi_period : time := 5 ns;
    constant clk_period : time := 10 ns;
    
    
begin
    u1 : tx port map(
        CPU_addr    => CPU_addr,
        CPU_we      => CPU_we,
        rst         => rst,
        clk         => clk,
        RAM_DATA    => data_ram,
        RAM_WE      => we_ram,
        RAM_RE      => re_ram,
        RAM_ADDR    => addr_ram,
        NI_ack      => ack_ni,
        NI_ready    => ready_ni,
        NI_data     => data_ni,
        NI_we       => we_ni
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

-----------------------------------------------------------------------------------------------------------
    -- Processus qui remplit la memoire
    fill_ram : process
    begin
        wait for 100 ns;
        -- On remplit le RB
        for i in 0 to 7 loop
            we_ram_B <= '1';
            din_ram_B <= X"81000100"; -- size = size_max = 256, eom = '1'
            addr_ram_B <= conv_std_logic_vector(8*i,32);
            wait for clk_period;
            
            we_ram_B <= '0';
            wait for clk_period;
            
            we_ram_B <= '1';
            din_ram_B <= conv_std_logic_vector(128 + (1024 * i), 32);
            addr_ram_B <= conv_std_logic_vector(8*i + 4, 32);
            wait for clk_period;
            
            we_ram_B <= '0';
            wait for clk_period;
        end loop;
        
        -- On remplit la memoire : pour le premier mot on met 0001 0001, le deuxième 0002 0002, etc ...
        -- On remplit les deux premières "barretes" de la memoire
        for i in 0 to 1 loop
            -- Chaque "barretes" contenent 256 mots de 4 octets
            for j in 0 to 255 loop
                we_ram_B <= '1';
                din_ram_B <= conv_std_logic_vector(i*256 + j, 16) & conv_std_logic_vector(i*256 + j, 16) ;
                addr_ram_B <= conv_std_logic_vector(128 + 1024*i + 4*j, 32);
                wait for clk_period;
                
                we_ram_B <= '0';
                wait for clk_period;
            end loop;
        end loop;
        -- On previent les autres processus que la ram est remplie : on peut commençer la simulation
        ram_fill <= '1';
        -- On arrete le processus
        wait on rst;
    end process;


-----------------------------------------------------------------------------------------------------------
    -- Processus qui lance la simu : on effectue l'action du CPU
    start : process
    begin
        wait on ram_fill;
        CPU_we <= '1';
        CPU_addr <= X"00000040";
        wait for clk_period;
        CPU_we <= '0';
        -- On arrete le processus
        wait on rst;
    end process;


-----------------------------------------------------------------------------------------------------------
    -- Processus qui simule l'autre NI
    ni_rx : process
    begin
        wait on ready_ni;
        wait for 4*clk_period;
        ack_ni <= '1';
        wait for clk_period;
        ack_ni <= '0';
    end process;
    
end Behavioral;
