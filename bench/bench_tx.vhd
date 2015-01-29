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
        rst          : in  STD_LOGIC;
        clk          : in  STD_LOGIC;
        -- Signaux de la RAM
        RAM_DATA     : in  STD_LOGIC_VECTOR (31 downto 0);
        RAM_RE       : out STD_LOGIC;
        RAM_ADDR     : out STD_LOGIC_VECTOR (31 downto 0);
        -- Signaux communquant avec l'autre ni
        NI_ack       : in  STD_LOGIC;
        NI_ready     : out STD_LOGIC;
        NI_data      : out STD_LOGIC_VECTOR (31 downto 0);
        NI_we        : out STD_LOGIC;
        NI_eom       : out STD_LOGIC;
        -- Signaux gérer par le CPU
        RB_SIZE      : in  STD_LOGIC_VECTOR (31 downto 0);
        WRITE        : in  STD_LOGIC_VECTOR (31 downto 0);
        READ         : out STD_LOGIC_VECTOR (31 downto 0);
        irq          : out STD_LOGIC
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
    signal rb_size      : STD_LOGIC_VECTOR (31 downto 0);
    signal write        : STD_LOGIC_VECTOR (31 downto 0);
    signal read         : STD_LOGIC_VECTOR (31 downto 0);
    
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
    
    -- irq vers le CPU
    signal irq_tx       : STD_LOGIC;
    
    constant clk_demi_period : time := 5 ns;
    constant clk_period : time := 10 ns;
    
    
begin
    u1 : tx port map(
        rst         => rst,
        clk         => clk,
        RAM_DATA    => data_ram,
        RAM_RE      => re_ram,
        RAM_ADDR    => addr_ram,
        NI_ack      => ack_ni,
        NI_ready    => ready_ni,
        NI_data     => data_ni,
        NI_we       => we_ni,
        RB_SIZE     => rb_size,
        WRITE       => write,
        READ        => read,
        irq         => irq_tx
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
    rb_size <= X"00000008";
    write   <= (0=> ram_fill, others => '0');

-----------------------------------------------------------------------------------------------------------
    -- Processus qui remplit la memoire
    fill_ram : process
    begin
        wait for 100 ns;
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
        
        -- On remplit la memoire : pour le premier mot on met 0000 0001, le deuxième 0000 0002, etc ...
        -- On remplit les huits "barretes" de la memoire
        for i in 0 to 7 loop
            -- Chaque "barretes" contenent 256 mots de 4 octets
            for j in 0 to 255 loop
                we_ram_B <= '1';
                din_ram_B <= conv_std_logic_vector(i*256 + j, 32);
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
