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

entity bench_ni is
end bench_ni;

architecture Behavioral of bench_ni is
    component ni 
        port( 
            clk             : in STD_LOGIC;
            rst             : in STD_LOGIC;
            -- Ports du CPU
            cpu_addr        : in STD_LOGIC_VECTOR (31 downto 0);
            cpu_data_in     : in STD_LOGIC_VECTOR (31 downto 0);
            cpu_data_out    : out STD_LOGIC_VECTOR (31 downto 0);
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
        --generic map (MEM_SIZE : integer);
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
        signal cpu_addr        : STD_LOGIC_VECTOR (31 downto 0);-- := (others => '0');
        signal cpu_data_in     : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        signal cpu_data_out    : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        signal cpu_we          : STD_LOGIC := '0';
        signal cpu_re          : STD_LOGIC := '0';
        signal irq             : STD_LOGIC := '0';
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
        signal cpu_addr2        : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        signal cpu_data2_in     : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        signal cpu_data2_out    : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        signal cpu_we2          : STD_LOGIC := '0';
        signal cpu_re2          : STD_LOGIC := '0';
        signal irq2             : STD_LOGIC := '0';
        -- Ports pour la RAM
        -- En tx
        signal ram_we_tx2       : STD_LOGIC;
        signal ram_re_tx2       : STD_LOGIC;
        signal ram_data_tx2     : STD_LOGIC_VECTOR (31 downto 0);
        signal ram_addr_tx2     : STD_LOGIC_VECTOR (31 downto 0);
        -- En rx
        signal ram_we_rx2       : STD_LOGIC;
        signal ram_re_rx2       : STD_LOGIC;
        signal ram_data_in_rx2  : STD_LOGIC_VECTOR (31 downto 0);
        signal ram_data_out_rx2 : STD_LOGIC_VECTOR (31 downto 0);
        signal ram_addr_rx2     : STD_LOGIC_VECTOR (31 downto 0);
        
        constant clk_demi_period :time := 5 ns;
        
        --signaux port B ram
        signal we_ram_B         : STD_LOGIC := '0';
        signal re_ram_B         : STD_LOGIC := '0';
        signal din_ram_B        : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        signal addr_ram_B       : STD_LOGIC_VECTOR (31 downto 0);
        signal ram_fill         : STD_LOGIC := '0';
        
        -- signaux ram rx
        signal we_ram_rx         : STD_LOGIC := '0';
        signal din_ram_rx        : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        signal addr_ram_rx       : STD_LOGIC_VECTOR (31 downto 0);

begin
--------------------------------------------------------------------------
-- NI 1
--------------------------------------------------------------------------
dut_ni_1: ni
    port map(
        clk             => clk,
        rst             => rst,
        -- Ports du CPU
        cpu_addr        => cpu_addr,
        cpu_data_in     => cpu_data_in,
        cpu_data_out    => cpu_data_out,
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
        din     => (others => '0'),
        dout    => ram_data_tx,
        --port 2
        we_B    => we_ram_B,
        re_B    => we_ram_B,
        addr_B  => addr_ram_B,
        din_B   => din_ram_B,
        dout_B  => open
    );
--------------------------------------------------------------------------
-- NI 2    
--------------------------------------------------------------------------
dut_ni_2: ni
    port map(
        clk             => clk,
        rst             => rst,
        -- Ports du CPU
        cpu_addr        => cpu_addr2,
        cpu_data_in     => cpu_data2_in,
        cpu_data_out    => cpu_data2_out,
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
        -- Ports pour l'autre NI on inverse le tx et le rx
        -- En tx
        NI_ack_tx       => NI_ack_rx,
        NI_ready_tx     => NI_ready_rx,
        NI_data_tx      => NI_data_rx,
        NI_we_tx        => NI_we_rx,
        NI_eom_tx       => NI_eom_rx,
        -- En rx
        NI_ack_rx       => NI_ack_tx,
        NI_ready_rx     => NI_ready_tx,
        NI_data_rx      => NI_data_tx,
        NI_we_rx        => NI_we_tx,
        NI_eom_rx       => NI_eom_tx
    
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
        we_B    => we_ram_rx,
        re_B    => '0',
        addr_B  => addr_ram_rx,
        din_B   => din_ram_rx,
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
    
   
clk <= not(clk) after clk_demi_period;
rst <= '1', '0' after 13*clk_demi_period;

-----------------------------------------------------------------------------------------
--TRAITEMEMT DES IRQ
-----------------------------------------------------------------------------------------
--NI 1
--p_cpu1: process(clk, rst, irq)
--begin
--    if rising_edge(irq) then
--        -- lecture du registre irq
--        cpu_re   <= '1';
--        cpu_addr <= X"00000034";
--        --assert cpu_data = "00000000000000000000000000000000" report 
--        --report cpu_data;
--    end if;
--end process p_cpu1;


----NI 2
--p_cpu2: process
--begin
--    wait for 10 ns;
--end process p_cpu2;


----------------------------------------------------------------------------------------
--SIMULATION DU CPU 1
--Ecriture dans la ram du tx 1
-----------------------------------------------------------------------------------------
--remplissage du rb size et de la ram
fill_ram_tx: process
begin
    wait for 15*clk_demi_period;
    -- On remplit le RB
    for i in 0 to 7 loop
        we_ram_B <= '1';
        -- On fait plusieurs tests different histoir de couvrir tout les cas
        case i is
            when 2 =>
                din_ram_B <= X"802D0100"; -- size = 45, size_max = 256, eom = '1'
            when 4 =>
                din_ram_B <= X"01000100"; -- size = size_max = 256, eom = '0'
            when 5 =>
                din_ram_B <= X"808E0100"; -- size = 142, size_max = 256, eom = '1'
            when others =>
                din_ram_B <= X"81000100"; -- size = size_max = 256, eom = '1'
        end case;
        addr_ram_B <= conv_std_logic_vector(8*i,32);
        wait for 2*clk_demi_period;
        
        we_ram_B <= '0';
        wait for 2*clk_demi_period;
        
        we_ram_B <= '1';
        din_ram_B <= conv_std_logic_vector(128 + (1024 * i), 32);
        addr_ram_B <= conv_std_logic_vector(8*i + 4, 32);
        wait for 2*clk_demi_period;
        
        we_ram_B <= '0';
        addr_ram_B <= (others => '0');
    end loop;
    
    -- On remplit la memoire : pour le premier mot on met 0000 0001, le deuxième 0000 0002, etc ...
    -- On remplit les huits "barretes" de la memoire
    for i in 0 to 7 loop
        -- Chaque "barretes" contenent 256 mots de 4 octets
        for j in 0 to 255 loop
            we_ram_B <= '1';
            din_ram_B <= conv_std_logic_vector(i*256 + j, 32);
            addr_ram_B <= conv_std_logic_vector(128 + 1024*i + 4*j, 32);
            wait for 2*clk_demi_period;
            we_ram_B <= '0';
        end loop;  
    end loop;
    we_ram_B <= '0';
    -- On previent les autres processus que la ram est remplie : on peut commençer la simulation
    ram_fill <= '1';
    -- On arrete le processus    
    wait on rst;
end process fill_ram_tx;


-----------------------------------------------------------------------------------------
-- Process de remplissage du RB (addr) pour la memoire rx
fill_ram_rx : process
begin
wait for 15*clk_demi_period;
    -- On remplit le RB
    for i in 0 to 7 loop
        we_ram_rx <= '1';
        din_ram_rx <= conv_std_logic_vector(128 + (1024 * i), 32);
        addr_ram_rx <= conv_std_logic_vector(8*i + 4, 32);
        wait for 2*clk_demi_period;
        
        we_ram_rx <= '0';
        addr_ram_rx <= (others => '0');
    end loop;
end process;

----------------------------------------------------------------------------------------
--INITIALISATION DU WRITE DU RB
-----------------------------------------------------------------------------------------
p_init: process
begin
    wait on ram_fill;
    cpu_we <= '1' ;
    cpu_data_in <= X"00000028";
    cpu_addr <= X"0000002c";
    wait for 2*clk_demi_period;
    cpu_we <= '0';
    cpu_data_in <= (others => '0');
    cpu_addr <= (others => '0');
    -- arret du process
    wait on rst;
end process p_init;
     
end Behavioral;
