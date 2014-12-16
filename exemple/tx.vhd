----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/25/2014 10:13:20 AM
-- Design Name: 
-- Module Name: tx - Behavioral
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

entity tx is
    Port ( CPU_addr      : in STD_LOGIC_VECTOR (31 downto 0);
           CPU_we        : in STD_LOGIC;
           rst           : in STD_LOGIC;
           clk           : in STD_LOGIC;
           ARREADY       : in STD_LOGIC;
           RVALID        : in STD_LOGIC;
           RDATA         : in STD_LOGIC_VECTOR (31 downto 0);
           ARVALID       : out STD_LOGIC;
           RREADY        : out STD_LOGIC;
           ARADDR        : out STD_LOGIC_VECTOR (31 downto 0)
           --NI_data       : out STD_LOGIC_VECTOR (31 downto 0);
           --NI_we         : out STD_LOGIC
           ;
end tx;

architecture Behavioral of tx is
    component fifo_tx 
PORT (
        clk    : IN STD_LOGIC;
        rst    : IN STD_LOGIC;
        din    : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_en  : IN STD_LOGIC;
        rd_en  : IN STD_LOGIC;
        dout   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        full   : OUT STD_LOGIC;
        empty  : OUT STD_LOGIC
      );
end component;

    type ETAT is (S_init, S_wait_instr, S_wait_rb_low, S_wait_rb_hi, S_send_addr, S_rec_data, S_end_data);
    
    signal etat_q, etat_d                     : ETAT;
    -- Signaux propre à la fifo
    signal fifo_in, fifo_out                  : std_logic_vector(31 downto 0);
    signal fifo_we, fifo_re                   : std_logic;
    signal fifo_empty, fifo_full              : std_logic;
    
    -- Signaux du descripteur du ring buffer (RB)
    signal addr_ram_q, addr_ram_d             : std_logic_vector(31 downto 0);
    signal size_rb_q, size_rb_d               : std_logic_vector(31 downto 0);
    signal read_q, read_d                     : std_logic_vector(31 downto 0);
    signal write_q, write_d                   : std_logic_vector(31 downto 0);
    
    -- Signaux permettant de stocker les données du RB
    signal actual_size_q, actual_size_d       : std_logic_vector(14 downto 0);
    signal size_max_q, size_max_d             : std_logic_vector(15 downto 0);
    signal end_of_msg_q, end_of_msg_d         : std_logic;
    signal addr_rb_q, addr_rb_d               : std_logic_vector(31 downto 0);
    
begin
    U1 : fifo_tx port map(
        clk     =>  clk,
        rst     =>  rst,
        din     =>  fifo_in,
        wr_en   =>  fifo_we,
        rd_en   =>  fifo_re,
        dout    =>  fifo_out,
        full    =>  fifo_full,
        empty   =>  fifo_empty
    );
    
    
-----------------------------------------------------------------------------------------------------------
    sync : process(clk, rst)
    begin
        if (CLK'event and CLK = '0') then
            if rst = '1' then
                etat_q <= S_init ;
            else
                etat_q             <= etat_d ;
                actual_size_q      <= actual_size_d ;
                size_max_q         <= size_max_d ;
                end_of_msg_q       <= end_of_msg_d ;
                addr_rb_q          <= addr_rb_d ;
                addr_ram_q         <= addr_ram_d ;
                size_rb_q          <= size_rb_d ;
                read_q             <= read_d ;
                write_q            <= write_d ;
                end if ;
        end if ;
    end process sync ;



-----------------------------------------------------------------------------------------------------------
    comb : process(etat_q, actual_size_q, size_max_q, end_of_msg_q, addr_rb_q, addr_ram_q, size_rb_q, read_q, write_q, 
                   CPU_we, CPU_addr, RVALID, ARREADY, RDATA, fifo_empty, fifo_full)
                   
        variable masque : std_logic_vector(31 downto 0);
    begin
    -- initialisation des signaux en entré du process combinatoire
        etat_d                  <= etat_q ;
        actual_size_d           <= actual_size_q ;
        size_max_d              <= size_max_q ;
        end_of_msg_d            <= end_of_msg_q ;
        addr_rb_d               <= addr_rb_q ;
        addr_ram_d              <= addr_ram_q ;
        size_rb_d               <= size_rb_q ;
        read_d                  <= read_q ;
        
        fifo_re                 <= '0' ;
        fifo_we                 <= '0' ;
        fifo_in                 <= (others => '0');
        RREADY                  <= '0' ;
        ARVALID                 <= '0' ;
        ARADDR                  <= (others => '0');
        
        -- On gère l'entrée du CPU à tout moment
        if(CPU_we = '1') then
            write_d <= CPU_addr;
        else
            write_d <= write_q ;
        end if;
        
        case etat_q is
            when S_init =>
                -- On suppose que l'adresse de la ram = 0 et size_rb = 8
                addr_ram_d <= (others => '0');
                size_rb_d <= (3 => '1', others => '0');
                -- Il faut initialiser read et write à addr_ram
                read_d <= (others => '0');
                write_d <= (others =>'0');
                etat_d <= S_wait_instr;
                
            when S_wait_instr =>
                -- On ne change d'état que si le dernier message reçu n'est pas le prochain buffer vide
                -- Il faut aussi que la fifo soit vide
                if(write_q /= read_q and fifo_empty = '1') then
                    etat_d <= S_wait_rb_low;
                end if;
                
            when S_wait_rb_low =>
                -- On change d'état lorsqu'on reçoit l'adresse de la prochaine data a enregistrer
                -- Sinon on la demande jusqu'a l'obtenirta : out STD_L
                if(RVALID = '1' and ARREADY = '1') then
                    RREADY <= '1';
                    -- On mémorise les données de size
                    size_max_d     <= RDATA(15 downto 0);
                    actual_size_d  <= RDATA(30 downto 16);
                    end_of_msg_d   <= RDATA(31);
                    -- On suppose ici que size_rb = 8
                    masque := (0 => '1', 1 => '1', 2 => '1', 3 => '1', others => '0');
                    read_d <= conv_std_logic_vector(unsigned(read_q) + 4,32) and masque;
                    etat_d <= S_wait_rb_hi;
                else
                    ARVALID  <= '1';
                    masque   := (3 => '0', others => '1');
                    ARADDR   <= read_q and masque;
                end if;
                
            when S_wait_rb_hi =>
                -- On change d'état lorsqu'on reçoit l'adresse de la prochaine data a enregistrer
                -- Sinon on la demande jusqu'a l'obtenir
                if(RVALID = '1' and ARREADY = '1') then
                    RREADY <= '1';
                    -- On mémorise l'adresse des données qui nous interraissent
                    addr_rb_d <= RDATA;
                    -- On suppose ici que size_rb = 8
                    masque := (0 => '1', 1 => '1', 2 => '1', 3 => '1', others => '0');
                    read_d <= conv_std_logic_vector(unsigned(read_q) + 4, 32) and masque;
                    etat_d <= S_send_addr;
                else
                    ARVALID <= '1';
                    ARADDR  <= read_q;
                end if;
                
            when S_send_addr =>
                -- On change d'état lorsqu'on reçoit la data demandée
                if(RVALID = '1' and ARREADY = '1') then
                    RREADY  <= '1';
                    -- On injecte la data dans la fifo
                    fifo_re <= '1';
                    fifo_in <= RDATA;
                    etat_d  <= S_rec_data;
                else
                    ARVALID <= '1';
                    ARADDR  <= addr_rb_q;
                end if;
                
            when S_rec_data =>
                -- La réception de data est considérer comme finit lorsque la fifo est pleine
                if(fifo_full = '0') then
                    addr_rb_d <= conv_std_logic_vector(unsigned(addr_rb_q) + 4, 32);
                    etat_d <= S_send_addr;
                else
                    etat_d <= S_end_data;
                end if;
                
            when S_end_data =>
                -- Si le message est finit on attend la prochaine instruction
                -- Sinon on prend le message suivant
                if(end_of_msg_q = '0') then
                    etat_d <= S_wait_instr;
                else
                    etat_d <= S_wait_rb_low;
                end if; 
                
        end case;
        
    end process comb;
end Behavioral;
