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
        M_IP_RB         : in std_logic_vector(31 downto 0);
        --Registres visibles à l'utilisateur
        RB_SIZE         : in std_logic_vector(31 downto 0);
        WRITE           : out std_logic_vector(31 downto 0);
        READ            : in std_logic_vector(31 downto 0)
    );
end rx;

architecture Behavioral of rx is

    component fifo 
        PORT (
            clk     : IN STD_LOGIC;
            srst    : IN STD_LOGIC;
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
    
    -- addr addresse de base de la ram
    signal descript_size_d, descript_size_q             : std_logic_vector(31 downto 0);
    signal descript_write_d, descript_write_q           : std_logic_vector(31 downto 0);
    signal descript_read_d, descript_read_q             : std_logic_vector(31 downto 0);    
    signal end_msg_d, end_msg_q     : std_logic := '0';
    --
    signal tap_number_d, tap_number_q               : std_logic;
    signal offset_d, offset_q                       : std_logic_vector(31 downto 0);
    signal nb_mots_ecrits_d, nb_mots_ecrits_q       : std_logic_vector(31 downto 0);--integer;
    signal ram_full_d, ram_full_q                   : std_logic;
    --signal fifo
    signal fifo_out     : std_logic_vector(31 downto 0);
    signal full, empty  : std_logic;
    signal rd_en        : std_logic;
    
    --Declare constants
    constant BUFFER_SIZE        : integer := 1024;  --4*256
            
    
begin

U_RX_FIFO: fifo 
    port map (
        clk     => CLK,
        srst    => RESET,
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
    if CLK'event and CLK = '1' then
        if RESET = '1' then 
            Etat_q                  <= S_init;
        else 
            Etat_q                  <= Etat_d;
            
            --descript_base _addr est directement implementé dans le ni
            descript_size_q         <= descript_size_d;
            descript_read_q         <= descript_read_d;
            descript_write_q        <= descript_write_d;
            end_msg_q               <= end_msg_d; 
            tap_number_q            <= tap_number_d; 
            nb_mots_ecrits_q        <= nb_mots_ecrits_d; 
            offset_q                <= offset_d;
            ram_full_q              <= ram_full_d;
        end if;
     end if;
end process P_SYNC;


---------------------------------------------------------------------------------------
--Process comb
P_COMB: process(Etat_q, 
                descript_read_q, descript_write_q, descript_size_q,
                offset_q, end_msg_q, nb_mots_ecrits_q,tap_number_q,ram_full_q,
                S_NOC_READY, S_NOC_WE, S_NOC_END_MSG, S_NOC_DATA, M_IP_RB,
                fifo_out, full, empty, READ, RB_SIZE)
    
    variable DESC_SIZE    : std_logic_vector(31 downto 0);
    variable mask         : std_logic_vector(31 downto 0);
    variable compteur     : std_logic_vector(31 downto 0);          

begin
    --initalisation des siganux (affectation par defaut)
    Etat_d                  <= Etat_q;
    
    descript_size_d         <= descript_size_q;
    descript_read_d         <= READ;
    descript_write_d        <= descript_write_q;
    WRITE                   <= descript_write_q;
    
    end_msg_d               <= end_msg_q; 
    tap_number_d            <= tap_number_q; 
    nb_mots_ecrits_d        <= nb_mots_ecrits_q; 
    offset_d                <= offset_q;
    ram_full_d              <= ram_full_q;
    
    S_NOC_VALID             <= '0';
    M_irq                   <= '0';
    M_IP_WE                 <= '0';
    M_IP_RE                 <= '0';
    M_IP_ADDR               <= (others => '0');
    M_IP_DATA               <= (others => '0');
    rd_en                   <= '0';
	
	
	if unsigned(descript_write_q) = unsigned(descript_read_q xor DESC_SIZE) then
		ram_full_d              <= ram_full_q;
	else
		ram_full_d              <= '0';
	end if;
    --multiplication du rb_size par 8 size*8
    DESC_SIZE               := RB_SIZE(28 downto 0) & "000";
    -- (size*8)*2 - 1
    mask                    := conv_std_logic_vector(unsigned(DESC_SIZE(30 downto 0) & '0') - 1,32);
        
    
    case etat_q is
        when S_init =>
            descript_size_d         <= DESC_SIZE;
            descript_read_d         <= READ;
            descript_write_d        <= (others => '0');
            end_msg_d               <= '0'; 
            tap_number_d            <= '0'; 
            nb_mots_ecrits_d        <= (others => '0'); 
            offset_d                <= (others => '0');
            ram_full_d              <= '0';     
            etat_d                  <= S_wait_request;
            
        when S_wait_request =>
            --attente de reception de debut de transfert fifo_tx -> fifo
            --le TX est pret a envoye des data
            if S_NOC_READY = '1' and ram_full_q = '0' then
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
                    if tap_number_q = '0' and unsigned(offset_q) = 0 then 
                        M_IP_RE         <= '1';
                        M_IP_ADDR       <= conv_std_logic_vector(unsigned(descript_write_q and not(DESC_SIZE)) + 4, 32);
                        tap_number_d    <= '1';
                    else
                        offset_d     <= M_IP_RB;
                        tap_number_d    <= '0';
                        rd_en <= '1';
                        etat_d <= S_write_ram;
                    end if;
                ram_full_d <= '0';
            else
                ram_full_d <= '1';
            end if;
            --irq
            
                        
        when S_write_ram =>             
            if empty = '0' then
                nb_mots_ecrits_d <= conv_std_logic_vector(unsigned(nb_mots_ecrits_q) + 4,32);
                rd_en       <= '1';
                M_IP_WE     <= '1';
                M_IP_ADDR   <= conv_std_logic_vector(unsigned(offset_q) + unsigned(nb_mots_ecrits_q),32);
                M_IP_DATA   <= fifo_out;
            else
                nb_mots_ecrits_d <= conv_std_logic_vector(unsigned(nb_mots_ecrits_q) + 4,32);
                rd_en       <= '1';
                M_IP_WE     <= '1';
                M_IP_ADDR   <= conv_std_logic_vector(unsigned(offset_q) + unsigned(nb_mots_ecrits_q),32);
                M_IP_DATA   <= fifo_out;
            
                etat_d <= S_end;
            end if;

            
        when S_end =>
            if (unsigned(nb_mots_ecrits_q) = BUFFER_SIZE) or end_msg_q = '1' then 
                M_IP_WE             <= '1';
                M_IP_ADDR           <= descript_write_q and not(DESC_SIZE);
                descript_write_d    <= conv_std_logic_vector(unsigned(descript_write_q) + 8 ,32) and  mask;
                end_msg_d           <= '0';         
                offset_d            <= (others => '0');
                nb_mots_ecrits_d    <= (others => '0');
                compteur := "00" & nb_mots_ecrits_q(29 downto 0);
                if end_msg_q = '1' then
                    M_IP_DATA <= '1' &compteur(14 downto 0) & X"0100";
                    M_irq <= '1';
                else
                    M_IP_DATA <= compteur(15 downto 0) & X"0100";
                end if;
            end if;
                
            etat_d <= S_wait_request;
        
    end case;
end process P_COMB;
end Behavioral;
