----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/20/2015 11:12:11 AM
-- Design Name: 
-- Module Name: ni - Behavioral
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

entity ni is
    Port ( 
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
    end ni;

architecture Behavioral of ni is

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
    
--     On définit les registres du NI comme des cellules mémoires
--     Tout les registres communs sont de la forme  |TX|RX|
--
--    (0) NI_RX_FIFO_DATA       Written into by the outerworld, slave access
--    (1) NI_RX_FIFO_STATUS     Number of items into the fifo, read only
--    (2) NI_RX_FIFO_SIZE       Number of slots of the fifo, a read only constant
--    (3) NI_RX_BUFFER_ADDR     Ring buffer address
--    (4) NI_RX_BUFFER_SIZE     size (256*4)
--    (5) NI_RX_BUFFER_START    start index (where to write)
--    (6) NI_RX_BUFFER_END      end index (where to read)

--    (7) NI_TX_FIFO_STATUS
--    (8) NI_TX_FIFO_SIZE
--    (9) NI_TX_BUFFER_ADDR     Ring buffer address
--    (10) NI_TX_BUFFER_SIZE    size (256*4)
--    (11) NI_TX_BUFFER_START   start index (where to write)
--    (12) NI_TX_BUFFER_END     end index (where to read)

--    (13) NI_IRQ_CAUSE         Reason why we raised an interrupt (4 different)
--    (14) NI_IRQ_ENABLE
--    (15) NI_WHO_AM_I          Placeholder for future discovery protocol
--    (16) NI_READY             aip sets it to 1 after startup to indicate it is initialized and ready

    type registre is array(0 to 16) of std_logic_vector(31 downto 0);

    signal registres    : registre;
        
    -- Signaux de jonction
    -- Pour le tx
    signal irq_tx       : std_logic;
    
    signal data_ram_tx  : std_logic_vector(31 downto 0);
    signal re_ram_tx    : std_logic;
    signal addr_ram_tx  : std_logic_vector(31 downto 0);
    signal offset_tx    : std_logic_vector(31 downto 0);
    
    
    signal ack_ni_tx    : std_logic;
    signal ready_ni_tx  : std_logic;
    signal data_ni_tx   : std_logic_vector(31 downto 0);
    signal we_ni_tx     : std_logic;
    signal eom_ni_tx    : std_logic;
    
    signal rb_size_tx   : std_logic_vector(31 downto 0);
    signal write_tx     : std_logic_vector(31 downto 0);
    signal read_tx      : std_logic_vector(31 downto 0);
    -- Pour le rx
    signal CPU_addr_rx  : std_logic_vector(31 downto 0);
    signal CPU_we_rx    : std_logic;
    signal irq_rx       : std_logic;
    signal data_ram_rx  : std_logic_vector(31 downto 0);
    signal rb_ram_rx    : std_logic_vector(31 downto 0);
    signal re_ram_rx    : std_logic;
    signal we_ram_rx    : std_logic;
    signal addr_ram_rx  : std_logic_vector(31 downto 0);
    signal offset_rx    : std_logic_vector(31 downto 0);
    
    signal ack_ni_rx    : std_logic;
    signal ready_ni_rx  : std_logic;
    signal data_ni_rx   : std_logic_vector(31 downto 0);
    signal we_ni_rx     : std_logic;
    signal eom_ni_rx    : std_logic;
    
    signal rb_size_rx   : std_logic_vector(31 downto 0);
    signal write_rx     : std_logic_vector(31 downto 0);
    signal read_rx      : std_logic_vector(31 downto 0);
    
begin

    u_tx : tx port map(
        rst         => rst,
        clk         => clk,
        RAM_DATA    => data_ram_tx,
        RAM_RE      => re_ram_tx,
        RAM_ADDR    => addr_ram_tx,
        NI_ack      => ack_ni_tx,
        NI_ready    => ready_ni_tx,
        NI_data     => data_ni_tx,
        NI_we       => we_ni_tx,
        NI_EOM      => eom_ni_tx,
        RB_SIZE     => rb_size_tx, --registres(10)
        WRITE       => write_tx, --registres(11)
        READ        => read_tx, --registres(12)
        irq         => irq_tx
    );
    
    u_rx: rx port map (
        CLK         => CLK,
        RESET       => rst,
        --ni_tx_data
        S_NOC_READY     => ready_ni_rx,
        S_NOC_VALID     => ack_ni_rx,
        S_NOC_DATA      => data_ni_rx,
        S_NOC_WE        => we_ni_rx,
        S_NOC_END_MSG   => eom_ni_rx,
        --irq to uC
        M_irq           => irq_rx,
        --local ram's signals
        M_IP_WE         => we_ram_rx,
        M_IP_RE         => re_ram_rx,
        M_IP_ADDR       => addr_ram_rx,
        M_IP_DATA       => data_ram_rx,
        M_IP_RB         => rb_ram_rx,
        --Registres visibles à l'utilisateur
        RB_SIZE     => rb_size_rx, --registres(4)
        WRITE       => write_rx, --registres(5)
        READ        => read_rx --registres(6)
    );


-----------------------------------------------------------------------------------------------------------
    -- Gestion des signaux d'entré/sortie du NI
    -- Ports pour la RAM
    -- En tx
    ram_we_tx       <= '0';
    ram_re_tx       <= re_ram_tx;
    data_ram_tx     <= ram_data_tx;
    ram_addr_tx     <= conv_std_logic_vector(unsigned(addr_ram_tx) + unsigned(offset_tx),32) ;
    -- En rx
    ram_we_rx       <= we_ram_rx;
    ram_re_rx       <= re_ram_rx;
    rb_ram_rx       <= ram_data_in_rx;
    ram_data_out_rx <= data_ram_rx;
    ram_addr_rx     <= conv_std_logic_vector(unsigned(addr_ram_rx) + unsigned(offset_rx),32) ;
    -- Ports pour l'autre NI
    -- En tx
    ack_ni_tx       <= NI_ack_tx;
    NI_ready_tx     <= ready_ni_tx;
    NI_data_tx      <= data_ni_tx;
    NI_we_tx        <= we_ni_tx;
    NI_eom_tx       <= eom_ni_tx;
    -- En rx
    NI_ack_rx       <= ack_ni_rx;
    ready_ni_rx     <= NI_ready_rx;
    data_ni_rx      <= NI_data_rx;
    we_ni_rx        <= NI_we_rx;
    eom_ni_rx       <= NI_eom_rx;
    

-----------------------------------------------------------------------------------------------------------
    -- Process séquentiel du NI de gestion des commandes CPU
    -- Ce process gère également les affectations des registres
    CPU_commande : process(clk, rst, CPU_addr, CPU_data_in, CPU_we, CPU_re, registres)
        begin
            if rst = '1' then
                rb_size_rx      <= (others => '0');
                read_rx         <= (others => '0');
                rb_size_tx      <= (others => '0');
                write_tx        <= (others => '0');
            
                registres(0)    <= (others => '0');
                registres(1)    <= (others => '0');
                registres(2)    <= (4 => '1', others => '0');
                registres(3)    <= (others => '0');
                registres(4)    <= (3 => '1', others => '0');
                registres(5)    <= (others => '0');
                registres(6)    <= (others => '0');
            
                registres(7)    <= (others => '0');
                registres(8)    <= (4 => '1', others => '0');
                registres(9)    <= (others => '0');
                registres(10)   <= (3 => '1', others => '0');
                registres(11)   <= (others => '0');
                registres(12)   <= (others => '0');
            
                registres(13)   <= (others => '0');
                registres(14)   <= (0 => '1', 1 => '1', others => '0');
                registres(15)   <= (others => '0');
                registres(16)   <= (0 => '1', others => '0');            
            else
                if (CLK'event and CLK = '1') then
                    -- in
                    offset_rx       <= registres(3);
                    rb_size_rx      <= registres(4);
                    read_rx         <= registres(6);
                    offset_tx       <= registres(9);
                    rb_size_tx      <= registres(10);
                    write_tx        <= registres(11);
                    irq  <= (registres(13)(0) and registres(14)(0)) or (registres(13)(1) and registres(14)(1));
                    -- out
                    registres(5)        <= write_rx;
                    registres(12)       <= read_tx;
                    
                    if(CPU_we = '1') then
                        case CPU_addr is
                            when X"00000000" =>
                                registres(0) <= CPU_data_in;
                            when X"00000004" =>
                                -- Variable read only
                            when X"00000008" =>
                                -- Variable read only
                            when X"0000000c" =>
                                registres(3) <= CPU_data_in;
                            when X"00000010" =>
                                registres(4) <= CPU_data_in;
                            when X"00000014" =>
                                -- Variable read only
                            when X"00000018" =>
                                registres(6) <= CPU_data_in;
                            when X"0000001c" =>
                                registres(7) <= CPU_data_in;
                            when X"00000020" =>
                                registres(8) <= CPU_data_in;
                            when X"00000024" =>
                                registres(9) <= CPU_data_in;
                            when X"00000028" =>
                                registres(10) <= CPU_data_in;
                            when X"0000002c" =>
                                registres(11) <= CPU_data_in;
                            when X"00000030" =>
                                -- Variable read only
                            when X"00000034" =>
                                registres(13) <= CPU_data_in;
                            when X"00000038" =>
                                registres(14) <= CPU_data_in;
                            when X"0000003c" =>
                                registres(15) <= CPU_data_in;
                            when X"00000040" =>
                                -- Variable read only NI_READY_D 
                            when others =>
                            -- On sort de la zone autorisée
                        end case;
                    else
                        registres(13)(0)    <= irq_rx;
                        registres(13)(1)    <= irq_tx;
                    end if;
                    
                    if(CPU_re = '1') then
                        case CPU_addr is
                            when X"00000000" =>
                                CPU_data_out <= registres(0);
                            when X"00000004" =>
                                CPU_data_out <= registres(1);
                            when X"00000008" =>
                                CPU_data_out <= registres(2);
                            when X"0000000c" =>
                                CPU_data_out <= registres(3);
                            when X"00000010" =>
                                CPU_data_out <= registres(4);
                            when X"00000014" =>
                                CPU_data_out <= registres(5);
                            when X"00000018" =>
                                CPU_data_out <= registres(6);
                            when X"0000001c" =>
                                CPU_data_out <= registres(7);
                            when X"00000020" =>
                                CPU_data_out <= registres(8);
                            when X"00000024" =>
                                CPU_data_out <= registres(9);
                            when X"00000028" =>
                                CPU_data_out <= registres(10);
                            when X"0000002c" =>
                                CPU_data_out <= registres(11);
                            when X"00000030" =>
                                CPU_data_out <= registres(12);
                            when X"00000034" =>
                                CPU_data_out <= registres(13);
                            when X"00000038" =>
                                CPU_data_out <= registres(14);
                            when X"0000003c" =>
                                CPU_data_out <= registres(15);
                            when X"00000040" =>
                                CPU_data_out <= registres(16);
                            when others =>
                                -- On sort de la zone autorisée
                        end case;
                    end if;
                end if;
            end if;
        end process CPU_commande ;

end Behavioral;
