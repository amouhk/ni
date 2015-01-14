----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.12.2014 19:34:39
-- Design Name: 
-- Module Name: ni_rx - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rx is
    Port ( 
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
        M_IP_RB         : in std_logic_vector(31 downto 0)
    );
end rx;

architecture Behavioral of rx is

    component fifo_rx 
        PORT (
            clk     : IN STD_LOGIC;
            rst     : IN STD_LOGIC;
            din     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_en   : IN STD_LOGIC;
            rd_en   : IN STD_LOGIC;
            dout    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            full    : OUT STD_LOGIC;
            empty   : OUT STD_LOGIC
        );
    end component;
    
    type   STATE is (S_init, S_wait_request, S_write_fifo, S_read_rb, S_write_ram, S_end );
    signal Etat_d, Etat_q   : STATE;
    
    --registres du ring buffer write et read sont des offset
    -- addr addresse de base de la ram
    signal descript_base_addr_d, descript_base_addr_q   : std_logic_vector(31 downto 0);
    signal descript_size_d, descript_size_q             : std_logic_vector(31 downto 0);
    signal descript_write_d, descript_write_q           : std_logic_vector(31 downto 0);
    signal descript_read_d, descript_read_q             : std_logic_vector(31 downto 0);
    signal end_msg_d, end_msg_q                         : std_logic := '0';
    -- Taille du buffer ou message
    signal actual_size_d, actual_size_q                 : std_logic_vector(31 downto 0);
    --
    signal tap_number_d, tap_number_q           : std_logic;
    signal offset_d, offset_q                   : std_logic_vector(31 downto 0);
    signal nb_mots_ecrits_d, nb_mots_ecrits_q   : integer;
    --signal fifo
    signal fifo_out     : std_logic_vector(31 downto 0);
    signal full, empty  : std_logic;
    signal rd_en        : std_logic;
    --signaux irq TODO
    
    --Declare constants
    constant MEM_BASE_ADDR      : std_logic_vector(31 downto 0) := (others => '0');
    constant DESC_SIZE          : std_logic_vector(31 downto 0) := ( 6 => '1', others => '0');  --8*(2*4)
    constant BUFFER_SIZE        : integer := 64;  --4*(16 or 256)
            
    
begin

U_RX_FIFO: fifo_rx 
    port map (
        clk     => CLK,
        rst     => RESET,
        din     => S_NOC_DATA,
        wr_en   => S_NOC_WE,
        rd_en   => rd_en,
        dout    => fifo_out,
        full    => full,
        empty   => empty
    );
---------------------------------------------------------------------------------------
--Process synchrone
P_SYNC: process(CLK, RESET)
begin
    if RESET = '1' then 
        Etat_q                  <= S_init;
     else 
        if CLK'event and CLK = '1' then
            Etat_q                  <= Etat_d;
            
            descript_base_addr_q    <= descript_base_addr_d;
            descript_size_q         <= descript_size_d;
            descript_read_q         <= descript_read_d;
            descript_write_q        <= descript_write_d;
            end_msg_q               <= end_msg_d; 
            tap_number_q            <= tap_number_d; 
            nb_mots_ecrits_q        <= nb_mots_ecrits_d; 
            actual_size_q           <= actual_size_d;
            offset_q                <= offset_d;
        end if;
     end if;
end process P_SYNC;


---------------------------------------------------------------------------------------
--Process comb
P_COMB: process(Etat_q, 
                descript_read_q, descript_write_q, descript_size_q, descript_base_addr_q,
                actual_size_q, offset_q, end_msg_q, nb_mots_ecrits_q,tap_number_q,
                S_NOC_READY, S_NOC_WE, S_NOC_END_MSG, S_NOC_DATA, M_IP_RB,
                fifo_out, full, empty)
                
    constant mask  : std_logic_vector(31 downto 0) := ( 6 => '0', others => '1');
    constant mask2 : std_logic_vector(31 downto 0) := ( 0 => '1', 1 => '1', 2 => '1', 3 => '1', 
                                                        4 => '1', 5 => '1', 6 => '1', others => '0');
begin
    --initalisation des siganux (affectation par defaut)
    Etat_d                  <= Etat_q;
    
    descript_base_addr_d    <= descript_base_addr_q;
    descript_size_d         <= descript_size_q;
    descript_read_d         <= descript_read_q;
    descript_write_d        <= descript_write_q;
    end_msg_d               <= end_msg_q; 
    tap_number_d            <= tap_number_q; 
    nb_mots_ecrits_d        <= nb_mots_ecrits_q; 
    actual_size_d           <= actual_size_q;
    offset_d                <= offset_q;
    
    S_NOC_VALID             <= '0';
    M_irq                   <= '0';
    M_IP_WE                 <= '0';
    M_IP_RE                 <= '0';
    M_IP_ADDR               <= (others => '0');
    M_IP_DATA               <= (others => '0');
    rd_en                   <= '0';
    
    case etat_q is
        when S_init =>
            descript_base_addr_d    <= MEM_BASE_ADDR;
            descript_size_d         <= DESC_SIZE;
            descript_read_d         <= (others => '0');
            descript_write_d        <= (others => '0');
            end_msg_d               <= '0'; 
            tap_number_d            <= '0'; 
            nb_mots_ecrits_d        <=  0; 
            actual_size_d           <= (others => '0');
            offset_d                <= (others => '0');
            etat_d <= S_wait_request;
            
        when S_wait_request =>
            --attente de reception de debut de transfert fifo_tx -> fifo_rx
            --le TX est pret a envoye des data
            if S_NOC_READY = '1' then
                S_NOC_VALID <= '1';
                etat_d <= S_write_fifo;
            end if;

        when S_write_fifo =>
            --Remplissage de la fifo
            -- La fifo se remplit a l'aide des signaux d'entres
            if S_NOC_WE = '0' and empty = '0' then
                etat_d <= S_read_rb;
            end if;
            -- on sauvegarde l'etat de end_msg
            if S_NOC_END_MSG = '1' then
                end_msg_d <= '1';
            end if;
  
        when S_read_rb =>
            --Lecture de l'adresse d'ecriture
            -- Avant, on verifie s'il y a de la place dans la RAM (buffers rx)
            if unsigned(descript_write_q) /= unsigned(descript_read_q xor DESC_SIZE) then
                if unsigned(offset_q) = 0 then 
                    if tap_number_q = '0' then 
                        M_IP_RE         <= '1';
                        M_IP_ADDR       <= conv_std_logic_vector(unsigned(descript_write_q and mask) + 4, 32);
                        tap_number_d    <= '1';
                    else
                        offset_d     <= M_IP_RB;
                        tap_number_d    <= '0';
                        rd_en <= '1';
                        etat_d <= S_write_ram;
                    end if;
              end if;
            else
                M_irq  <= '1';
            end if;
            --irq
            
                        
        when S_write_ram =>             
            if empty = '0' then
                nb_mots_ecrits_d <= nb_mots_ecrits_q + 4;
                rd_en       <= '1';
                M_IP_WE     <= '1';
                M_IP_ADDR   <= conv_std_logic_vector(unsigned(offset_q) + nb_mots_ecrits_q,32);
                M_IP_DATA   <= fifo_out;
                actual_size_d      <= conv_std_logic_vector(unsigned(actual_size_q) + 4,32);
            else
                nb_mots_ecrits_d <= nb_mots_ecrits_q + 4;
                rd_en       <= '1';
                M_IP_WE     <= '1';
                M_IP_ADDR   <= conv_std_logic_vector(unsigned(offset_q) + nb_mots_ecrits_q,32);
                M_IP_DATA   <= fifo_out;
                actual_size_d      <= conv_std_logic_vector(unsigned(actual_size_q) + 4,32);
            
                etat_d <= S_end;
            end if;

            
        when S_end =>
            if (nb_mots_ecrits_q = BUFFER_SIZE) or end_msg_q = '1' then 
                M_IP_WE             <= '1';
                M_IP_ADDR           <= descript_write_q and mask;
                M_IP_DATA           <= conv_std_logic_vector(unsigned(actual_size_q), 32);
                actual_size_d              <= (others => '0');
                descript_write_d    <= conv_std_logic_vector(unsigned(descript_write_q) + 8 ,32) and  mask2;
                end_msg_d           <= '0';         
                offset_d            <= (others => '0');
                nb_mots_ecrits_d    <= 0;
            end if;
                
            etat_d <= S_wait_request;
        
    end case;
end process P_COMB;
end Behavioral;
