----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/20/2015 11:34:18 AM
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bench_ni is
end bench_ni;

architecture Behavioral of bench_ni is
    component ni 
        port( 
            clk             : in STD_LOGIC;
            rst             : in STD_LOGIC;
            -- Ports du CPU
            cpu_addr        : in STD_LOGIC_VECTOR (31 downto 0);
            cpu_data        : inout STD_LOGIC_VECTOR (31 downto 0);
            cpu_we          : in STD_LOGIC;
            cpu_re          : in STD_LOGIC;
            irq             : out STD_LOGIC;
            -- Ports pour la RAM
            -- En tx
            ram_we_tx       : out STD_LOGIC;
            ram_re_tx       : out STD_LOGIC;
            ram_data_tx     : in STD_LOGIC_VECTOR (31 downto 0);
            ram_addr_tx     : out STD_LOGIC_VECTOR (31 downto 0);
            -- En rx
            ram_we_rx       : out STD_LOGIC;
            ram_re_rx       : out STD_LOGIC;
            ram_data_in_rx  : in  STD_LOGIC_VECTOR (31 downto 0);
            ram_data_out_rx : out STD_LOGIC_VECTOR (31 downto 0);
            ram_addr_rx     : out STD_LOGIC_VECTOR (31 downto 0);
            -- Ports pour l'autre NI
            -- En tx
            NI_ack_tx       : in STD_LOGIC;
            NI_ready_tx     : out STD_LOGIC;
            NI_data_tx      : out STD_LOGIC_VECTOR (31 downto 0);
            NI_we_tx        : out STD_LOGIC;
            NI_eom_tx       : out STD_LOGIC;
            -- En rx
            NI_ack_rx       : out STD_LOGIC;
            NI_ready_rx     : in STD_LOGIC;
            NI_data_rx      : in STD_LOGIC_VECTOR (31 downto 0);
            NI_we_rx        : in STD_LOGIC;
            NI_eom_rx       : in STD_LOGIC
        );
    end component;
    
    component MEM_RAM
        port(
            CLK     : in  STD_LOGIC;
            RESET   : in  STD_LOGIC;
            --1er port
            addr    : in  STD_LOGIC_VECTOR (31 downto 0);
            din     : in  STD_LOGIC_VECTOR (31 downto 0);
            dout    : out  STD_LOGIC_VECTOR (31 downto 0);
            we      : in  STD_LOGIC;
            re      : in  STD_LOGIC;
            -- 2ème port
            addr_B  : in  STD_LOGIC_VECTOR (31 downto 0);
            din_B   : in  STD_LOGIC_VECTOR (31 downto 0);
            dout_B  : out  STD_LOGIC_VECTOR (31 downto 0);
            we_B    : in  STD_LOGIC;
            re_B    : in  STD_LOGIC
        
        );
    end component;
    

        signal clk             : STD_LOGIC := '0';
        signal rst             : STD_LOGIC := '1';
        --PORT NI 1
        -- Ports du CPU
        signal cpu_addr        : STD_LOGIC_VECTOR (31 downto 0);
        signal cpu_data        : STD_LOGIC_VECTOR (31 downto 0);
        signal cpu_we          : STD_LOGIC;
        signal cpu_re          : STD_LOGIC;
        signal irq             : STD_LOGIC;
        -- Ports pour la RAM
        -- En tx
        signal ram_we_tx       : STD_LOGIC;
        signal ram_re_tx       : STD_LOGIC;
        signal ram_data_tx     : STD_LOGIC_VECTOR (31 downto 0);
        signal ram_addr_tx     : STD_LOGIC_VECTOR (31 downto 0);
        -- En rx
        signal ram_we_rx       : STD_LOGIC;
        signal ram_re_rx       : STD_LOGIC;
        signal ram_data_in_rx     : STD_LOGIC_VECTOR (31 downto 0);
        signal ram_data_out_rx     : STD_LOGIC_VECTOR (31 downto 0);
        signal ram_addr_rx     : STD_LOGIC_VECTOR (31 downto 0);
        
        -- Port en commun avec l'autre ni
        -- En tx
        signal NI_ack_tx       : STD_LOGIC;
        signal NI_ready_tx     : STD_LOGIC;
        signal NI_data_tx      : STD_LOGIC_VECTOR (31 downto 0);
        signal NI_we_tx        : STD_LOGIC;
        signal NI_eom_tx       : STD_LOGIC;
        -- En rx
        signal NI_ack_rx       : STD_LOGIC;
        signal NI_ready_rx     : STD_LOGIC;
        signal NI_data_rx      : STD_LOGIC_VECTOR (31 downto 0);
        signal NI_we_rx        : STD_LOGIC;
        signal NI_eom_rx       : STD_LOGIC;
        
        --PORT du NI 2
        -- Ports du CPU
        signal cpu_addr2       : STD_LOGIC_VECTOR (31 downto 0);
        signal cpu_data2        : STD_LOGIC_VECTOR (31 downto 0);
        signal cpu_we2          : STD_LOGIC;
        signal cpu_re2          : STD_LOGIC;
        signal irq2             : STD_LOGIC;
        -- Ports pour la RAM
        -- En tx
        signal ram_we_tx2       : STD_LOGIC;
        signal ram_re_tx2       : STD_LOGIC;
        signal ram_data_tx2     : STD_LOGIC_VECTOR (31 downto 0);
        signal ram_addr_tx2     : STD_LOGIC_VECTOR (31 downto 0);
        -- En rx
        signal ram_we_rx2       : STD_LOGIC;
        signal ram_re_rx2       : STD_LOGIC;
        signal ram_data_in_rx2     : STD_LOGIC_VECTOR (31 downto 0);
        signal ram_data_out_rx2     : STD_LOGIC_VECTOR (31 downto 0);
        signal ram_addr_rx2     : STD_LOGIC_VECTOR (31 downto 0);
        
        constant clk_period :time := 5 ns;

begin
--------------------------------------------------------------------------
--------------------------------------------------------------------------
dut_ni_1: ni
    port map(
        clk             => clk,
        rst             => rst,
        -- Ports du CPU
        cpu_addr        => cpu_addr,
        cpu_data        => cpu_data,
        cpu_we          => cpu_we,
        cpu_re          => cpu_re,
        irq             => irq,
        -- Ports pour la RAM
        -- En tx
        ram_we_tx       => ram_we_tx,
        ram_re_tx       => ram_re_tx ,
        ram_data_tx     => ram_data_tx,
        ram_addr_tx     => ram_addr_tx,
        -- En rx
        ram_we_rx       => ram_we_rx,
        ram_re_rx       => ram_re_rx,
        ram_data_in_rx  => ram_data_in_rx,
        ram_data_out_rx => ram_data_out_rx,
        ram_addr_rx     => ram_addr_rx,
        -- Ports pour l'autre NI
        -- En tx
        NI_ack_tx       => NI_ack_tx,
        NI_ready_tx     => NI_ready_tx,
        NI_data_tx      => NI_data_tx,
        NI_we_tx        => NI_we_tx,
        NI_eom_tx       => NI_eom_tx,
        -- En rx
        NI_ack_rx       => NI_ack_rx,
        NI_ready_rx     => NI_ready_rx,
        NI_data_rx      => NI_data_rx,
        NI_we_rx        => NI_we_rx,
        NI_eom_rx       => NI_eom_rx
    
    );
    
du_ram_rx_1: MEM_RAM
    --generic map (MEM_SIZE => 9000)
    port map(
        CLK     => clk, 
        RESET   => rst,
        --port 1
        we      => ram_we_rx,
        re      => ram_re_rx,
        addr    => ram_addr_rx,
        din     => ram_data_in_rx,
        dout    => ram_data_out_rx,
        --port 2
        we_B    => '0',
        re_B    => '0',
        addr_B  => (others => '0'),
        din_B   => (others => '0'),
        dout_B  => open
    );
    
du_ram_tx_1: MEM_RAM
    --generic map (MEM_SIZE => 9000)
    port map(
        CLK     => clk, 
        RESET   => rst,
        --port 1
        we      => ram_we_tx,
        re      => ram_re_tx,
        addr    => ram_addr_tx,
        din     => ram_data_tx,
        dout    => open,
        --port 2
        we_B    => '0',
        re_B    => '0',
        addr_B  => (others => '0'),
        din_B   => (others => '0'),
        dout_B  => open
    );
--------------------------------------------------------------------------    
--------------------------------------------------------------------------
dut_ni_2: ni
    port map(
        clk             => clk,
        rst             => rst,
        -- Ports du CPU
        cpu_addr        => cpu_addr2,
        cpu_data        => cpu_data2,
        cpu_we          => cpu_we2,
        cpu_re          => cpu_re2,
        irq             => irq2,
        -- Ports pour la RAM
        -- En tx
        ram_we_tx       => ram_we_tx2,
        ram_re_tx       => ram_re_tx2 ,
        ram_data_tx     => ram_data_tx2,
        ram_addr_tx     => ram_addr_tx2,
        -- En rx
        ram_we_rx       => ram_we_rx2,
        ram_re_rx       => ram_re_rx2,
        ram_data_in_rx  => ram_data_in_rx2,
        ram_data_out_rx => ram_data_out_rx2,
        ram_addr_rx     => ram_addr_rx2,
        -- Ports pour l'autre NI
        -- En tx
        NI_ack_tx       => NI_ack_tx,
        NI_ready_tx     => NI_ready_tx,
        NI_data_tx      => NI_data_tx,
        NI_we_tx        => NI_we_tx,
        NI_eom_tx       => NI_eom_tx,
        -- En rx
        NI_ack_rx       => NI_ack_rx,
        NI_ready_rx     => NI_ready_rx,
        NI_data_rx      => NI_data_rx,
        NI_we_rx        => NI_we_rx,
        NI_eom_rx       => NI_eom_rx
    
    );
    
du_ram_rx_2: MEM_RAM
    --generic map (MEM_SIZE => 9000)
    port map(
        CLK     => clk, 
        RESET   => rst,
        --port 1
        we      => ram_we_rx2,
        re      => ram_re_rx2,
        addr    => ram_addr_rx2,
        din     => ram_data_in_rx2,
        dout    => ram_data_out_rx2,
        --port 2
        we_B    => '0',
        re_B    => '0',
        addr_B  => (others => '0'),
        din_B   => (others => '0'),
        dout_B  => open
    );
    
du_ram_tx_2: MEM_RAM
    --generic map (MEM_SIZE => 9000)
    port map(
        CLK     => clk, 
        RESET   => rst,
        --port 1
        we      => ram_we_tx2,
        re      => ram_re_tx2,
        addr    => ram_addr_tx2,
        din     => ram_data_tx2,
        dout    => open,
        --port 2
        we_B    => '0',
        re_B    => '0',
        addr_B  => (others => '0'),
        din_B   => (others => '0'),
        dout_B  => open
    );   
    
   
clk <= not(clk) after clk_period;
rst <= '1', '0' after 10*clk_period;

---------------------------------------
p_cpu1: process
begin
    wait for 10 ns;
end process p_cpu1;
---------------------------------------
p_cpu2: process
begin
    wait for 10 ns;
end process p_cpu2;

   
     
end Behavioral;
