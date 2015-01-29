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
    Port ( rst          : in  STD_LOGIC;
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
end tx;

architecture Behavioral of tx is
    component fifo_tx 
PORT (
        clk    : IN STD_LOGIC;
        srst    : IN STD_LOGIC;
        din    : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_en  : IN STD_LOGIC;
        rd_en  : IN STD_LOGIC;
        dout   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        full   : OUT STD_LOGIC;
        empty  : OUT STD_LOGIC
      );
end component;

    type ETAT is (S_init, S_wait_instr, S_read_rb, S_write_fifo, S_rec_data, S_wait_ni, S_send_data, S_end_data);
    
    signal etat_q, etat_d                     : ETAT;
    signal Tap_Number, Next_Tap_Number        : std_logic_vector(1 downto 0); -- On code 4 etapes differentes
    -- Signaux propre a la fifo
    signal fifo_in, fifo_out                  : std_logic_vector(31 downto 0);
    signal fifo_we, fifo_re                   : std_logic;
    signal fifo_empty, fifo_full              : std_logic;
    
    -- registre read
    signal read_d, read_q                     : std_logic_vector(31 downto 0);
    -- Signaux permettant de stocker les donnees du RB
    signal actual_size_q, actual_size_d       : std_logic_vector(14 downto 0);
    signal size_max_q, size_max_d             : std_logic_vector(15 downto 0);
    signal end_of_msg_q, end_of_msg_d         : std_logic;
    signal addr_ram_q, addr_ram_d             : std_logic_vector(31 downto 0);
    
    -- indique combien de mot sont encor a lire pour iterer sur le RB
    signal nb_mot_restant_q, nb_mot_restant_d       : std_logic_vector(15 downto 0);
    
begin
    U1 : fifo_tx port map(
        clk     =>  clk,
        srst    =>  rst,
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
        if (CLK'event and CLK = '1') then
            if rst = '1' then
                etat_q <= S_init ;
            else
                etat_q             <= etat_d ;
                Tap_Number         <= Next_Tap_Number;
                actual_size_q      <= actual_size_d ;
                size_max_q         <= size_max_d ;
                end_of_msg_q       <= end_of_msg_d ;
                addr_ram_q         <= addr_ram_d ;
                nb_mot_restant_q   <= nb_mot_restant_d;
                read_q             <= read_d;
            end if ;
        end if ;
    end process sync ;



-----------------------------------------------------------------------------------------------------------
    comb : process(etat_q, Tap_Number, actual_size_q, size_max_q, end_of_msg_q, 
                   addr_ram_q, nb_mot_restant_q, RAM_DATA, fifo_empty, fifo_full, 
                   fifo_out, NI_ack, WRITE, read_q, RB_SIZE)
                   
        variable masque : std_logic_vector(31 downto 0);
    begin
    -- initialisation des signaux en entre du process combinatoire
        Next_Tap_Number         <= Tap_Number;
        etat_d                  <= etat_q ;
        actual_size_d           <= actual_size_q ;
        size_max_d              <= size_max_q ;
        end_of_msg_d            <= end_of_msg_q ;
        addr_ram_d              <= addr_ram_q ;
        nb_mot_restant_d        <= nb_mot_restant_q ;
        read_d                  <= read_q;
        
        fifo_re                 <= '0' ;
        fifo_we                 <= '0' ;
        fifo_in                 <= (others => '0');
        RAM_RE                  <= '0' ;
        RAM_ADDR                <= (others => '0');
        NI_ready                <= '0' ;
        NI_data                 <= (others => '0');
        NI_we                   <= '0' ;
        NI_eom                  <= '0' ;
        irq                     <= '0' ;
        -- A tout moment la sortie read correspond à l'état courant du registre
        READ                    <= read_q;

        
        case etat_q is
            when S_init =>
                -- Initialisation de tout les registres
                actual_size_d           <= (others => '0') ;
                size_max_d              <= (others => '0') ;
                end_of_msg_d            <= '0' ;
                addr_ram_d              <= (others => '0') ;
                nb_mot_restant_d        <= (others => '0') ;
                read_d                  <= (others => '0') ;

                Next_Tap_Number <= "00";
                etat_d <= S_wait_instr;
                
            when S_wait_instr =>
                -- On initialise le nombre de mots restant : la prochaine etape consiste a lire le RB
                nb_mot_restant_d <= (others => '0');
                -- On ne change d'etat que si le dernier message reçu n'est pas le prochain buffer vide
                -- Il faut aussi que la fifo soit vide
                if(WRITE /= read_q and fifo_empty = '1') then
                    etat_d <= S_read_rb;
                end if;
                
            when S_read_rb =>
                case Tap_Number is
                    when "00" =>
                        -- On onvoit la demande de lecture de size du RB
                        RAM_RE    <= '1';
                        masque    := not (RB_SIZE(28 downto 0) & "000");
                        RAM_ADDR  <= read_q and masque;
                        Next_Tap_Number <= "01";
                
                    when "01"=> 
                        -- On memorise les donnees de size
                        size_max_d     <= RAM_DATA(15 downto 0);
                        actual_size_d  <= RAM_DATA(30 downto 16);
                        end_of_msg_d   <= RAM_DATA(31);
                        -- On en profite pour initialiser le nomre de mot restant a actual_size
                        nb_mot_restant_d  <= '0' & RAM_DATA(30 downto 16);
                        -- Sachant qu'un mot du rb fait 8 octets, on incemente modulo 2*8*RB_SIZE
                        masque := conv_std_logic_vector(unsigned(RB_SIZE(27 downto 0) & "0000") - 1, 32);
                        read_d <= conv_std_logic_vector(unsigned(read_q) + 4,32) and masque;
                        Next_Tap_Number <= "10";
                
                    when "10" =>
                        -- On envoit la demande de lecture de l'adresse du RB
                        RAM_RE    <= '1';
                        masque    := not (RB_SIZE(28 downto 0) & "000");
                        RAM_ADDR  <= read_q and masque;
                        Next_Tap_Number <= "11";
                        
                    when "11" =>
                        -- On memorise l'adresse des donnees qui nous interraissent
                        addr_ram_d <= RAM_DATA;
                        -- Sachant qu'un mot du rb fait 8 octets, on incemente modulo 2*8*RB_SIZE
                        masque := conv_std_logic_vector(unsigned(RB_SIZE(27 downto 0) & "0000") - 1, 32);
                        read_d <= conv_std_logic_vector(unsigned(read_q) + 4, 32) and masque;
                        Next_Tap_Number <= "00";
                        etat_d <= S_write_fifo;
                    when others =>
                        -- A priori ce cas n'existe pas
                end case;
                
            when S_write_fifo =>
                if(Tap_Number = "00") then
                    -- On interroge la memoire
                    RAM_RE <= '1';
                    RAM_ADDR  <= addr_ram_q;
                    Next_Tap_Number <= "01";
                else
                    -- On injecte la data dans la fifo
                    fifo_we <= '1';
                    fifo_in <= RAM_DATA;
                    Next_Tap_Number <= "00";
                    -- Chaque fois qu'on ecrit dans la fifo le nombre de mots restant diminue
                    -- Attention le nombre de mots restant ne doit pas etre negatif
                    if(nb_mot_restant_q > 0) then
                        nb_mot_restant_d <= conv_std_logic_vector(unsigned(nb_mot_restant_q) - 1, 16);
                    end if;
                    
                    if(nb_mot_restant_q = 0) then
                        etat_d <= S_wait_ni;
                    else
                        etat_d  <= S_rec_data;
                    end if;
                end if;

            when S_rec_data =>
                addr_ram_d <= conv_std_logic_vector(unsigned(addr_ram_q) + 4, 32);
                -- La reception de data est considerer comme finit lorsque la fifo est pleine
                if(fifo_full = '0') then
                    etat_d <= S_write_fifo;
                else
                    etat_d <= S_wait_ni;
                end if;
            
            when S_wait_ni =>
                -- On interroge l'autre NI : si celui-ci est pret on envoit les data
                -- Sinon on attend
                NI_ready <= '1';
                if(NI_ack = '1') then
                    Next_Tap_Number <= "00";
                    etat_d <= S_send_data ;
                end if;
                
            when S_send_data =>
                fifo_re <= '1';
                -- Il faut attendre 1 cycle avant que la fifo ne se vide
                if(Tap_Number = "00") then
                    Next_Tap_Number <= "01";
                else
                    NI_we   <= '1';
                    -- On indique au NI et au CPU que le message est termine 
                    -- uniquement a l'envoit de la derniere trame
                    if(nb_mot_restant_q = 0) then
                        NI_eom <= end_of_msg_q;
                    end if;
                end if;
                NI_data <= fifo_out;
                
                if(fifo_empty = '1') then
                    Next_Tap_Number <= "00";
                    etat_d <= S_end_data;
                end if;
            
            when S_end_data =>
                -- Si la barrete memoire n'est pas finit on la continue, sinon on passe au prochain element du rb
                if(nb_mot_restant_q = 0) then
                    irq    <= end_of_msg_q;
                    etat_d <= S_wait_instr ;
                else
                    etat_d  <= S_write_fifo;
                end if;
        end case;
        
    end process comb;
end Behavioral;
