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
        ram_data_rx     : out STD_LOGIC_VECTOR (31 downto 0);
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
        rst          : in STD_LOGIC;
        clk          : in STD_LOGIC;
        CPU_addr     : in STD_LOGIC_VECTOR (31 downto 0);
        CPU_we       : in STD_LOGIC;
        RAM_DATA     : in STD_LOGIC_VECTOR (31 downto 0);
        RAM_RE       : out STD_LOGIC;
        RAM_ADDR     : out STD_LOGIC_VECTOR (31 downto 0);
        NI_ack       : in STD_LOGIC;
        NI_ready     : out STD_LOGIC;
        NI_data      : out STD_LOGIC_VECTOR (31 downto 0);
        NI_we        : out STD_LOGIC;
        NI_eom       : out STD_LOGIC;
        irq          : out STD_LOGIC
    );
    end component;
   
   
    component rx port (
        CLK             : in  std_logic;
        RESET           : in std_logic;
        --entrees du CPU
        CPU_addr        : in std_logic_vector(31 downto 0);
        CPU_we          : in std_logic;
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
        M_IP_RB         : in std_logic_vector(31 downto 0)
    );
    end component;
    
    
    -- Signaux de jonction
    -- Pour le tx
    signal CPU_addr_tx  : std_logic_vector(31 downto 0);
    signal CPU_we_tx    : std_logic;
    signal irq_tx       : std_logic;
    
    signal data_ram_tx  : std_logic_vector(31 downto 0);
    signal re_ram_tx    : std_logic;
    signal addr_ram_tx  : std_logic_vector(31 downto 0);
    
    signal ack_ni_tx    : std_logic;
    signal ready_ni_tx  : std_logic;
    signal data_ni_tx   : std_logic_vector(31 downto 0);
    signal we_ni_tx     : std_logic;
    signal eom_ni_tx    : std_logic;
    -- Pour le rx
    signal CPU_addr_rx  : std_logic_vector(31 downto 0);
    signal CPU_we_rx    : std_logic;
    signal irq_rx       : std_logic;
    
    signal data_ram_rx  : std_logic_vector(31 downto 0);
    signal rb_ram_rx    : std_logic_vector(31 downto 0);
    signal re_ram_rx    : std_logic;
    signal we_ram_rx    : std_logic;
    signal addr_ram_rx  : std_logic_vector(31 downto 0);
    
    signal ack_ni_rx    : std_logic;
    signal ready_ni_rx  : std_logic;
    signal data_ni_rx   : std_logic_vector(31 downto 0);
    signal we_ni_rx     : std_logic;
    signal eom_ni_rx    : std_logic;
    
    
    -- Les registres
    -- Tout les registres communs sont de la forme  |TX|RX|
    signal NI_RX_FIFO_DATA_D, NI_RX_FIFO_DATA_Q         : std_logic_vector(31 downto 0);     --Written into by the outerworld, slave access
    signal NI_RX_FIFO_STATUS_D, NI_RX_FIFO_STATUS_Q     : std_logic_vector(31 downto 0);    --Number of items into the fifo, read only
    signal NI_RX_FIFO_SIZE_D , NI_RX_FIFO_SIZE_Q        : std_logic_vector(31 downto 0);   --Number of slots of the fifo, a read only constant
    signal NI_RX_BUFFER_ADDR_D, NI_RX_BUFFER_ADDR_Q     : std_logic_vector(31 downto 0);    --Ring buffer address
    signal NI_RX_BUFFER_SIZE_D, NI_RX_BUFFER_SIZE_Q     : std_logic_vector(31 downto 0);    --size (256*4)
    signal NI_RX_BUFFER_START_D, NI_RX_BUFFER_START_Q   : std_logic_vector(31 downto 0);    -- start index (where to write)
    signal NI_RX_BUFFER_END_D , NI_RX_BUFFER_END_Q      : std_logic_vector(31 downto 0);    --end index (where to read)

    signal NI_TX_FIFO_STATUS_D, NI_TX_FIFO_STATUS_Q     : std_logic_vector(31 downto 0);
    signal NI_TX_FIFO_SIZE_D, NI_TX_FIFO_SIZE_Q         : std_logic_vector(31 downto 0);
    signal NI_TX_BUFFER_ADDR_D, NI_TX_BUFFER_ADDR_Q     : std_logic_vector(31 downto 0);      --Ring buffer address
    signal NI_TX_BUFFER_SIZE_D, NI_TX_BUFFER_SIZE_Q     : std_logic_vector(31 downto 0);  --size (256*4)
    signal NI_TX_BUFFER_START_D, NI_TX_BUFFER_START_Q   : std_logic_vector(31 downto 0);   -- start index (where to write)
    signal NI_TX_BUFFER_END_D, NI_TX_BUFFER_END_Q       : std_logic_vector(31 downto 0);   --end index (where to read)

    signal NI_IRQ_CAUSE_D, NI_IRQ_CAUSE_Q               : std_logic_vector(31 downto 0);     --Reason why we raised an interrupt (4 different)
    signal NI_IRQ_ENABLE_D, NI_IRQ_ENABLE_Q             : std_logic_vector(31 downto 0);
    signal NI_WHO_AM_I_D, NI_WHO_AM_I_Q                 : std_logic_vector(31 downto 0);    --Placeholder for future discovery protocol
    signal NI_READY_D, NI_READY_Q                       : std_logic_vector(31 downto 0);     --aip sets it to 1 after startup to indicate it is initialized and ready

    -- Host rx ring buffer
    signal NI_HOST_RX_BUFFER_ADDR_D, NI_HOST_RX_BUFFER_ADDR_Q       : std_logic_vector(31 downto 0);    --Ring buffer address
    signal NI_HOST_RX_BUFFER_SIZE_D, NI_HOST_RX_BUFFER_SIZE_Q       : std_logic_vector(31 downto 0);   -- size
    signal NI_HOST_RX_BUFFER_START_D, NI_HOST_RX_BUFFER_START_Q     : std_logic_vector(31 downto 0);    --start index (where to write)
    signal NI_HOST_RX_BUFFER_END_D, NI_HOST_RX_BUFFER_END_Q         : std_logic_vector(31 downto 0);  --end index (where to read)

    -- Host tx ring buffer
    signal NI_HOST_TX_BUFFER_ADDR_D, NI_HOST_TX_BUFFER_ADDR_Q        : std_logic_vector(31 downto 0);    --Ring buffer address
    signal NI_HOST_TX_BUFFER_SIZE_D, NI_HOST_TX_BUFFER_SIZE_Q        : std_logic_vector(31 downto 0);    --size
    signal NI_HOST_TX_BUFFER_START_D, NI_HOST_TX_BUFFER_START_Q      : std_logic_vector(31 downto 0);   --start index (where to write)
    signal NI_HOST_TX_BUFFER_END_D, NI_HOST_TX_BUFFER_END_Q          : std_logic_vector(31 downto 0);   --end index (where to read)

    -- Host interrupt
    signal NI_HOST_IRQ_CAUSE_D, NI_HOST_IRQ_CAUSE_Q             : std_logic_vector(31 downto 0);   --Reason why we raised an interrupt
    signal NI_HOST_IRQ_ENABLE_D, NI_HOST_IRQ_ENABLE_Q           : std_logic_vector(31 downto 0);

begin


    u_tx : tx port map(
        rst         => rst,
        clk         => clk,
        CPU_addr    => CPU_addr_tx,
        CPU_we      => CPU_we_tx,
        RAM_DATA    => data_ram_tx,
        RAM_RE      => re_ram_tx,
        RAM_ADDR    => addr_ram_tx,
        NI_ack      => ack_ni_tx,
        NI_ready    => ready_ni_tx,
        NI_data     => data_ni_tx,
        NI_we       => we_ni_tx,
        NI_EOM      => eom_ni_tx,
        irq         => irq_tx
    );
    
    u_rx: rx port map (
        CLK         => CLK,
        RESET       => rst,
        CPU_addr    => CPU_addr_rx,
        CPU_we      => CPU_we_rx,
        --ni_tx_data
        S_NOC_READY     => ready_ni_rx,
        S_NOC_VALID     => ack_ni_rx,
        S_NOC_DATA      => data_ni_rx,
        S_NOC_WE        =>  we_ni_rx,
        S_NOC_END_MSG   => eom_ni_rx,
        --irq to uC
        M_irq           => irq_rx,
        --local ram's signals
        M_IP_WE         => we_ram_rx,
        M_IP_RE         => re_ram_rx,
        M_IP_ADDR       => addr_ram_rx,
        M_IP_DATA       => data_ram_rx,
        M_IP_RB         => rb_ram_rx
    );
    

-----------------------------------------------------------------------------------------------------------
    -- Process séquentiel du NI
    sync : process(clk, rst)
    begin
        if (CLK'event and CLK = '1') then
            if rst = '1' then
                NI_RX_FIFO_DATA_Q       <= (others => '0');
                NI_RX_FIFO_STATUS_Q     <= (others => '0');
                NI_RX_FIFO_SIZE_Q       <= (4 => '1', others => '0');
                NI_RX_BUFFER_ADDR_Q     <= (others => '0');
                NI_RX_BUFFER_SIZE_Q     <= (10 => '1', others => '0');
                NI_RX_BUFFER_START_Q    <= (others => '0');
                NI_RX_BUFFER_END_Q      <= (others => '0');
            
                NI_TX_FIFO_STATUS_Q     <= (others => '0');
                NI_TX_FIFO_SIZE_Q       <= (4 => '1', others => '0');
                NI_TX_BUFFER_ADDR_Q     <= (others => '0');
                NI_TX_BUFFER_SIZE_Q     <= (10 => '1', others => '0');
                NI_TX_BUFFER_START_Q    <= (others => '0');
                NI_TX_BUFFER_END_Q      <= (others => '0');
            
                NI_IRQ_CAUSE_Q          <= (others => '0');
                NI_IRQ_ENABLE_Q         <= (others => '0');
                NI_WHO_AM_I_Q           <= (others => '0');
                NI_READY_Q              <= (others => '0');
            
                NI_HOST_RX_BUFFER_ADDR_Q    <= (others => '0');
                NI_HOST_RX_BUFFER_SIZE_Q    <= (4 => '1', others => '0');
                NI_HOST_RX_BUFFER_START_Q   <= (others => '0');
                NI_HOST_RX_BUFFER_END_Q     <= (others => '0');
            
                NI_HOST_TX_BUFFER_ADDR_Q    <= (others => '0');
                NI_HOST_TX_BUFFER_SIZE_Q    <= (4 => '1', others => '0');
                NI_HOST_TX_BUFFER_START_Q   <= (others => '0');
                NI_HOST_TX_BUFFER_END_Q     <= (others => '0');
            
                NI_HOST_IRQ_CAUSE_Q         <= (others => '0');
                NI_HOST_IRQ_ENABLE_Q        <= (others => '0');
                
            else
                NI_RX_FIFO_DATA_Q       <= NI_RX_FIFO_DATA_D;
                NI_RX_FIFO_STATUS_Q     <= NI_RX_FIFO_STATUS_D;
                NI_RX_FIFO_SIZE_Q       <= NI_RX_FIFO_SIZE_D;
                NI_RX_BUFFER_ADDR_Q     <= NI_RX_BUFFER_ADDR_D;
                NI_RX_BUFFER_SIZE_Q     <= NI_RX_BUFFER_SIZE_D;
                NI_RX_BUFFER_START_Q    <= NI_RX_BUFFER_START_D;
                NI_RX_BUFFER_END_Q      <= NI_RX_BUFFER_END_D;
            
                NI_TX_FIFO_STATUS_Q     <= NI_TX_FIFO_STATUS_D;
                NI_TX_FIFO_SIZE_Q       <= NI_TX_FIFO_SIZE_D;
                NI_TX_BUFFER_ADDR_Q     <= NI_TX_BUFFER_ADDR_D;
                NI_TX_BUFFER_SIZE_Q     <= NI_TX_BUFFER_SIZE_D;
                NI_TX_BUFFER_START_Q    <= NI_TX_BUFFER_START_D;
                NI_TX_BUFFER_END_Q      <= NI_TX_BUFFER_END_D;
            
                NI_IRQ_CAUSE_Q          <= NI_IRQ_CAUSE_D;
                NI_IRQ_ENABLE_Q         <= NI_IRQ_ENABLE_D;
                NI_WHO_AM_I_Q           <= NI_WHO_AM_I_D;
                NI_READY_Q              <= NI_READY_D;
            
                NI_HOST_RX_BUFFER_ADDR_Q    <= NI_HOST_RX_BUFFER_ADDR_D;
                NI_HOST_RX_BUFFER_SIZE_Q    <= NI_HOST_RX_BUFFER_SIZE_D;
                NI_HOST_RX_BUFFER_START_Q   <= NI_HOST_RX_BUFFER_START_D;
                NI_HOST_RX_BUFFER_END_Q     <= NI_HOST_RX_BUFFER_END_D;
            
                NI_HOST_TX_BUFFER_ADDR_Q    <= NI_HOST_TX_BUFFER_ADDR_D;
                NI_HOST_TX_BUFFER_SIZE_Q    <= NI_HOST_TX_BUFFER_SIZE_D;
                NI_HOST_TX_BUFFER_START_Q   <= NI_HOST_TX_BUFFER_START_D;
                NI_HOST_TX_BUFFER_END_Q     <= NI_HOST_TX_BUFFER_END_D;
            
                NI_HOST_IRQ_CAUSE_Q         <= NI_HOST_IRQ_CAUSE_D;
                NI_HOST_IRQ_ENABLE_Q        <= NI_HOST_IRQ_ENABLE_D;
            end if ;
        end if ;
    end process sync ;
    
    
-----------------------------------------------------------------------------------------------------------
    -- Branchement des registres
    register_plug : process(NI_RX_FIFO_DATA_Q, NI_RX_FIFO_STATUS_Q, NI_RX_FIFO_SIZE_Q, NI_RX_BUFFER_ADDR_Q,
                            NI_RX_BUFFER_SIZE_Q, NI_RX_BUFFER_START_Q, NI_RX_BUFFER_END_Q, NI_TX_FIFO_STATUS_Q,
                            NI_TX_FIFO_SIZE_Q, NI_TX_BUFFER_ADDR_Q, NI_TX_BUFFER_SIZE_Q, NI_TX_BUFFER_START_Q,
                            NI_TX_BUFFER_END_Q, NI_IRQ_CAUSE_Q, NI_IRQ_ENABLE_Q, NI_WHO_AM_I_Q,
                            NI_READY_Q, NI_HOST_RX_BUFFER_ADDR_Q, NI_HOST_RX_BUFFER_SIZE_Q, NI_HOST_RX_BUFFER_START_Q,
                            NI_HOST_RX_BUFFER_END_Q, NI_HOST_TX_BUFFER_ADDR_Q, NI_HOST_TX_BUFFER_SIZE_Q, NI_HOST_TX_BUFFER_START_Q,
                            NI_HOST_TX_BUFFER_END_Q, NI_HOST_IRQ_CAUSE_Q, NI_HOST_IRQ_ENABLE_Q
                            )
        begin                    
            NI_RX_FIFO_DATA_D       <= NI_RX_FIFO_DATA_Q;
            NI_RX_FIFO_STATUS_D     <= NI_RX_FIFO_STATUS_Q;
            NI_RX_FIFO_SIZE_D       <= NI_RX_FIFO_SIZE_Q;
            NI_RX_BUFFER_ADDR_D     <= NI_RX_BUFFER_ADDR_Q;
            NI_RX_BUFFER_SIZE_D     <= NI_RX_BUFFER_SIZE_Q;
            NI_RX_BUFFER_START_D    <= NI_RX_BUFFER_START_Q;
            NI_RX_BUFFER_END_D      <= NI_RX_BUFFER_END_Q;
        
            NI_TX_FIFO_STATUS_D     <= NI_TX_FIFO_STATUS_Q;
            NI_TX_FIFO_SIZE_D       <= NI_TX_FIFO_SIZE_Q;
            NI_TX_BUFFER_ADDR_D     <= NI_TX_BUFFER_ADDR_Q;
            NI_TX_BUFFER_SIZE_D     <= NI_TX_BUFFER_SIZE_Q;
            NI_TX_BUFFER_START_D    <= NI_TX_BUFFER_START_Q;
            NI_TX_BUFFER_END_D      <= NI_TX_BUFFER_END_Q;
        
            NI_IRQ_CAUSE_D          <= NI_IRQ_CAUSE_Q;
            NI_IRQ_ENABLE_D         <= NI_IRQ_ENABLE_Q;
            NI_WHO_AM_I_D           <= NI_WHO_AM_I_Q;
            NI_READY_D              <= NI_READY_Q;
        
            NI_HOST_RX_BUFFER_ADDR_D    <= NI_HOST_RX_BUFFER_ADDR_Q;
            NI_HOST_RX_BUFFER_SIZE_D    <= NI_HOST_RX_BUFFER_SIZE_Q;
            NI_HOST_RX_BUFFER_START_D   <= NI_HOST_RX_BUFFER_START_Q;
            NI_HOST_RX_BUFFER_END_D     <= NI_HOST_RX_BUFFER_END_Q;
        
            NI_HOST_TX_BUFFER_ADDR_D    <= NI_HOST_TX_BUFFER_ADDR_Q;
            NI_HOST_TX_BUFFER_SIZE_D    <= NI_HOST_TX_BUFFER_SIZE_Q;
            NI_HOST_TX_BUFFER_START_D   <= NI_HOST_TX_BUFFER_START_Q;
            NI_HOST_TX_BUFFER_END_D     <= NI_HOST_TX_BUFFER_END_Q;
        
            NI_HOST_IRQ_CAUSE_D         <= NI_HOST_IRQ_CAUSE_Q;
            NI_HOST_IRQ_ENABLE_D        <= NI_HOST_IRQ_ENABLE_Q;
        end process register_plug ;
    

-----------------------------------------------------------------------------------------------------------
    -- Gestion des commandes CPU
    CPU_commande : process( clk, CPU_addr, CPU_data, CPU_we, CPU_re,
                            NI_RX_FIFO_DATA_Q, NI_RX_FIFO_STATUS_Q, NI_RX_FIFO_SIZE_Q, NI_RX_BUFFER_ADDR_Q,
                            NI_RX_BUFFER_SIZE_Q, NI_RX_BUFFER_START_Q, NI_RX_BUFFER_END_Q, NI_TX_FIFO_STATUS_Q,
                            NI_TX_FIFO_SIZE_Q, NI_TX_BUFFER_ADDR_Q, NI_TX_BUFFER_SIZE_Q, NI_TX_BUFFER_START_Q,
                            NI_TX_BUFFER_END_Q, NI_IRQ_CAUSE_Q, NI_IRQ_ENABLE_Q, NI_WHO_AM_I_Q,
                            NI_READY_Q, NI_HOST_RX_BUFFER_ADDR_Q, NI_HOST_RX_BUFFER_SIZE_Q, NI_HOST_RX_BUFFER_START_Q,
                            NI_HOST_RX_BUFFER_END_Q, NI_HOST_TX_BUFFER_ADDR_Q, NI_HOST_TX_BUFFER_SIZE_Q, NI_HOST_TX_BUFFER_START_Q,
                            NI_HOST_TX_BUFFER_END_Q, NI_HOST_IRQ_CAUSE_Q, NI_HOST_IRQ_ENABLE_Q
                            )
        begin
            if (CLK'event and CLK = '1') then
                if(CPU_we = '1') then
                    case CPU_addr is
                        when X"00000000" =>
                            NI_RX_FIFO_DATA_D <= CPU_data;
                        when X"00000004" =>
                            -- Variable read only
                        when X"00000008" =>
                            -- Variable read only
                        when X"0000000c" =>
                            NI_RX_BUFFER_ADDR_D <= CPU_data;
                        when X"00000010" =>
                            NI_RX_BUFFER_SIZE_D <= CPU_data;
                        when X"00000014" =>
                            NI_RX_BUFFER_START_D <= CPU_data;
                        when X"00000018" =>
                            NI_RX_BUFFER_END_D <= CPU_data;
                        when X"0000001c" =>
                            NI_TX_FIFO_STATUS_D <= CPU_data;
                        when X"00000020" =>
                            NI_TX_FIFO_SIZE_D <= CPU_data;
                        when X"00000024" =>
                            NI_TX_BUFFER_ADDR_D <= CPU_data;
                        when X"00000028" =>
                            NI_TX_BUFFER_SIZE_D <= CPU_data;
                        when X"0000002c" =>
                            NI_TX_BUFFER_START_D <= CPU_data;
                        when X"00000030" =>
                            NI_TX_BUFFER_END_D <= CPU_data;
                        when X"00000034" =>
                            NI_IRQ_CAUSE_D <= CPU_data;
                        when X"00000038" =>
                            NI_IRQ_ENABLE_D <= CPU_data;
                        when X"0000003c" =>
                            NI_WHO_AM_I_D <= CPU_data;
                        when X"00000040" =>
                            NI_READY_D <= CPU_data;
                        when X"00000044" =>
                            NI_HOST_RX_BUFFER_ADDR_D <= CPU_data;
                        when X"00000048" =>
                            NI_HOST_RX_BUFFER_SIZE_D <= CPU_data;
                        when X"0000004c" =>
                            NI_HOST_RX_BUFFER_START_D <= CPU_data;
                        when X"00000050" =>
                            NI_HOST_RX_BUFFER_END_D <= CPU_data;
                        when X"00000054" =>
                            NI_HOST_TX_BUFFER_ADDR_D <= CPU_data;
                        when X"00000058" =>
                            NI_HOST_TX_BUFFER_SIZE_D <= CPU_data;
                        when X"0000005c" =>
                            NI_HOST_TX_BUFFER_START_D <= CPU_data;
                        when X"00000060" =>
                            NI_HOST_TX_BUFFER_END_D <= CPU_data;
                        when X"00000064" =>
                            NI_HOST_IRQ_CAUSE_D <= CPU_data;
                        when X"00000068" =>
                            NI_HOST_IRQ_ENABLE_D <= CPU_data;
                        when others =>
                        -- On sort de la zone autorisée
                    end case;
                end if;
                
                if(CPU_re = '1') then
                    case CPU_addr is
                        when X"00000000" =>
                            CPU_data <= NI_RX_FIFO_DATA_Q;
                        when X"00000004" =>
                            CPU_data <= NI_RX_FIFO_STATUS_Q;
                        when X"00000008" =>
                            CPU_data <= NI_RX_FIFO_SIZE_Q;
                        when X"0000000c" =>
                            CPU_data <= NI_RX_BUFFER_ADDR_Q;
                        when X"00000010" =>
                            CPU_data <= NI_RX_BUFFER_SIZE_Q;
                        when X"00000014" =>
                            CPU_data <= NI_RX_BUFFER_START_Q;
                        when X"00000018" =>
                            CPU_data <= NI_RX_BUFFER_END_Q;
                        when X"0000001c" =>
                            CPU_data <= NI_TX_FIFO_STATUS_Q;
                        when X"00000020" =>
                            CPU_data <= NI_TX_FIFO_SIZE_Q;
                        when X"00000024" =>
                            CPU_data <= NI_TX_BUFFER_ADDR_Q;
                        when X"00000028" =>
                            CPU_data <= NI_TX_BUFFER_SIZE_Q;
                        when X"0000002c" =>
                            CPU_data <= NI_TX_BUFFER_START_Q;
                        when X"00000030" =>
                            CPU_data <= NI_TX_BUFFER_END_Q;
                        when X"00000034" =>
                            CPU_data <= NI_IRQ_CAUSE_Q;
                        when X"00000038" =>
                            CPU_data <= NI_IRQ_ENABLE_Q;
                        when X"0000003c" =>
                            CPU_data <= NI_WHO_AM_I_Q;
                        when X"00000040" =>
                            CPU_data <= NI_READY_Q;
                        when X"00000044" =>
                            CPU_data <= NI_HOST_RX_BUFFER_ADDR_Q;
                        when X"00000048" =>
                            CPU_data <= NI_HOST_RX_BUFFER_SIZE_Q;
                        when X"0000004c" =>
                            CPU_data <= NI_HOST_RX_BUFFER_START_Q;
                        when X"00000050" =>
                            CPU_data <= NI_HOST_RX_BUFFER_END_Q;
                        when X"00000054" =>
                            CPU_data <= NI_HOST_TX_BUFFER_ADDR_Q;
                        when X"00000058" =>
                            CPU_data <= NI_HOST_TX_BUFFER_SIZE_Q;
                        when X"0000005c" =>
                            CPU_data <= NI_HOST_TX_BUFFER_START_Q;
                        when X"00000060" =>
                            CPU_data <= NI_HOST_TX_BUFFER_END_Q;
                        when X"00000064" =>
                            CPU_data <= NI_HOST_IRQ_CAUSE_Q;
                        when X"00000068" =>
                            CPU_data <= NI_HOST_IRQ_ENABLE_Q;
                        when others =>
                            -- On sort de la zone autorisée
                    end case;
                end if;
            end if;
        end process CPU_commande ;

end Behavioral;
