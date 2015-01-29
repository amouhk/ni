----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/16/2015 04:47:49 PM
-- Design Name: 
-- Module Name: bench_rx_tx - Behavioral
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

entity bench_rx_tx is
end bench_rx_tx;

architecture Behavioral of bench_rx_tx is
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

    component rx port (
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
        M_IP_RB         : in std_logic_vector(31 downto 0);
        --Registres visibles à l'utilisateur
        RB_SIZE         : in std_logic_vector(31 downto 0);
        WRITE           : out std_logic_vector(31 downto 0);
        READ            : in std_logic_vector(31 downto 0)
    );
    end component;
       
    
    component RAM
        generic( MEM_SIZE : integer := 9000 );
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

--signaux genere par le bench
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal rb_size_tx   : std_logic_vector(31 downto 0) := (3 => '1', others => '0');
    signal write_tx     : std_logic_vector(31 downto 0) := (others => '0');
    signal read_tx      : std_logic_vector(31 downto 0) ;
    signal rb_size_rx   : std_logic_vector(31 downto 0) := (3 => '1', others => '0');
    signal write_rx     : std_logic_vector(31 downto 0);
    signal read_rx      : std_logic_vector(31 downto 0) := (others => '0');

    signal din_ram      : std_logic_vector(31 downto 0) := (others => '0');
    signal din_ram_B    : std_logic_vector(31 downto 0) := (others => '0');
    signal addr_ram_B   : std_logic_vector(31 downto 0) := (others => '0');
    signal data_ram_B   : std_logic_vector(31 downto 0) := (others => '0');
    signal re_ram_B     : std_logic := '0';
    signal we_ram_B     : std_logic := '0';
    signal ram_fill     : std_logic := '0';
    
    -- jonction entre les composants
    signal addr_ram     : std_logic_vector(31 downto 0);
    signal data_ram     : std_logic_vector(31 downto 0);
    signal re_ram       : std_logic;
    signal we_ram       : std_logic;
    signal ack_ni       : STD_LOGIC;
    signal ready_ni     : STD_LOGIC;
    signal data_ni      : STD_LOGIC_VECTOR (31 downto 0);
    signal we_ni        : STD_LOGIC;
    signal eom_ni       : STD_LOGIC;
    
    --irq to uC
    signal irq_rx        : std_logic;
    signal irq_tx       : std_logic;
    --local ram's signals
    signal M_IP_WE      :  std_logic ;
    signal M_IP_RE      :  std_logic;
    signal M_IP_ADDR    :  std_logic_vector(31 downto 0);
    signal M_IP_DATA    :  std_logic_vector(31 downto 0):= (others => '0');
    signal M_IP_RB      :  std_logic_vector(31 downto 0):= (others => '0');
    
    signal re_fill      :  std_logic:= '0';
    signal we_fill      :  std_logic:= '0';
    signal addr_fill    :  std_logic_vector(31 downto 0):= (others => '0');
    signal data_fill    :  std_logic_vector(31 downto 0):= (others => '0') ;
    signal data_out     :  std_logic_vector(31 downto 0);

    constant clk_demi_period : time := 5 ns;
    constant clk_period : time := 10 ns;

begin

    u_tx : tx port map(
        rst         => rst,
        clk         => clk,
        RAM_DATA    => data_ram,
        RAM_RE      => re_ram,
        RAM_ADDR    => addr_ram,
        NI_ack      => ack_ni,
        NI_ready    => ready_ni,
        NI_data     => data_ni,
        NI_we       => we_ni,
        NI_EOM      => eom_ni,
        RB_SIZE     => rb_size_tx,
        WRITE       => write_tx,
        READ        => read_tx,
        irq         => irq_tx
    );
    
    u_mem : MEM_RAM port map(
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

    u_ram: RAM
    generic map (MEM_SIZE => 9000)
    port map(
        CLK     => CLK, 
        RESET   => rst,
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

    u_rx: rx port map (
        CLK         => CLK,
        RESET       => rst,
        --ni_tx_data
        S_NOC_READY     => ready_ni,
        S_NOC_VALID     => ack_ni,
        S_NOC_DATA      => data_ni,
        S_NOC_WE        =>  we_ni,
        S_NOC_END_MSG   => eom_ni,
        --irq to uC
        M_irq           => irq_rx,
        --local ram's signals
        M_IP_WE         => M_IP_WE,
        M_IP_RE         => M_IP_RE,
        M_IP_ADDR       => M_IP_ADDR,
        M_IP_DATA       => M_IP_DATA,
        M_IP_RB         => M_IP_RB,
        --Registres visibles à l'utilisateur
        RB_SIZE         => rb_size_rx,
        WRITE           => write_rx,
        READ            => read_rx
    );


    CLK <= not(CLK) after clk_demi_period; -- periode 10 ns
    Rst <= '1', '0' after 50 ns;
    -- lancement de la simu
    write_tx <= (0 => '1', others => '0') when (ram_fill = '1')  else (others => '0');


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


end Behavioral;