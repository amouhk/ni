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
        S_NOC_BEG_MSG   : in std_logic;
        --irq to uC
        M_irq           : out std_logic;
        --local ram's signals
        M_IP_WE         : out std_logic;
        M_IP_RE         : out std_logic;
        M_IP_ADDR       : out std_logic_vector(31 downto 0);
        M_IP_DATA       : out std_logic_vector(31 downto 0)
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
    
    type   STATE is (S_wait_request, S_wait_full, S_load_addr, S_read_fifo, S_load_msg, S_load_size );
    signal Etat_d, Etat_q   : STATE;
    
    --registres du ring buffer write et read sont des offset
    -- addr addresse de base de la ram
    signal descript_base_addr_d, descript_base_addr_q   : std_logic_vector(31 downto 0);
    signal descript_size_d, descript_size_q             : std_logic_vector(31 downto 0);
    signal descript_write_d, descript_write_q           : std_logic_vector(31 downto 0);
    signal descript_read_d, descript_read_q             : std_logic_vector(31 downto 0);
    
    signal end_msg_d, end_msg_q                         : std_logic := '0';
    signal beg_msg_d, beg_msg_q                         : std_logic := '0';
    
    --descripteur de la ram
    signal size_d, size_q                       : std_logic_vector(31 downto 0);
    signal temp_addr_d, temp_addr_q             : std_logic_vector(31 downto 0);
    
    --signaux irq TODO
    
    --signal fifo
    signal fifo_out     : std_logic_vector(31 downto 0);
    signal full, empty  : std_logic;
    signal rd_en        : std_logic;
    
    --constants
    constant MEM_BASE_ADDR      : std_logic_vector(31 downto 0) := (others => '0');
    constant DESC_SIZE	        : std_logic_vector(31 downto 0) := ( 3 => '1', others => '0');  --8*(2*4)
    constant BUFFER_SIZE	    : std_logic_vector(31 downto 0) := ( 6 => '1', others => '0');  --4*(16 or 256)
    constant DATA_BASE_ADDR	    : std_logic_vector(31 downto 0) := ( 6 => '1', others => '0');  --2*8*4
    constant DATA_MEM_SIZE      : std_logic_vector(31 downto 0) := ( 9 => '1', others => '0');  --4*(16 or 256)*8
    --constant maskBuffer         : std_logic_vector(31 downto 0) := ( 0 => '1', 1 => '1', 2 => '1', 3 => '1', 4 => '1', 5 => '1', 6 => '1',others=> '0');
    
    
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
        Etat_q                  <= S_wait_request;
        descript_base_addr_q    <= MEM_BASE_ADDR;
        descript_size_q         <= DESC_SIZE;
        descript_read_q         <= MEM_BASE_ADDR;
        descript_write_q        <= MEM_BASE_ADDR;
        temp_addr_q             <= DATA_BASE_ADDR;
        size_q                  <= (others => '0');

     else 
        if CLK'event and CLK = '1' then
            Etat_q                  <= Etat_d;
            
            descript_base_addr_q    <= descript_base_addr_d;
            descript_size_q         <= descript_size_d;
            descript_read_q         <= descript_read_d;
            descript_write_q        <= descript_write_d;
            
            end_msg_q               <= end_msg_d; 
            beg_msg_q               <= beg_msg_d; 
            size_q                  <= size_d;
            temp_addr_q             <= temp_addr_d;
        end if;
     end if;
end process P_SYNC;


---------------------------------------------------------------------------------------
--Process comb
P_COMB: process(Etat_q, 
                descript_read_q, descript_write_q, descript_size_q, descript_base_addr_q,
                size_q, temp_addr_q, end_msg_q, beg_msg_q,
                S_NOC_READY, S_NOC_WE, S_NOC_END_MSG,S_NOC_DATA,fifo_out, 
                full, empty)
begin
    --initalisation des siganux (affectation par defaut)
    Etat_d                  <= Etat_q;
    descript_base_addr_d    <= descript_base_addr_q;
    descript_size_d         <= descript_size_q;
    descript_write_d        <= descript_write_q;
    descript_read_d         <= descript_read_q;
    end_msg_d               <= end_msg_q;
    beg_msg_d               <= beg_msg_q;
    size_d                  <= size_q;
    
    temp_addr_d     <= temp_addr_q;
    S_NOC_VALID     <= '0';
    M_irq           <= '0'; -- irq enable;
    M_IP_WE         <= '0';
    M_IP_RE         <= '0';
    M_IP_ADDR       <= (others => '0');
    M_IP_DATA       <= (others => '0');
    rd_en       <= '0';
    
    case etat_q is
            
        when S_wait_request =>
            end_msg_d   <= '0';
            beg_msg_d   <= '0';
            --attente de reception de debut de transfert fifo_tx -> fifo_rx
            --le TX est pret à envoyé des data
            if S_NOC_READY = '1' then
                S_NOC_VALID <= '1';
                etat_d <= S_wait_full;
            end if;
            
            
        when S_wait_full => 
            --Attente de remplissage de la fifo par tx
            --on attend soit que a fifo soit pleine ou la reception du dernier msg
            if S_NOC_BEG_MSG = '1' then
                beg_msg_d <= '1';
            end if;
            
            if S_NOC_END_MSG = '1' then
                end_msg_d <= '1';
            end if;
            
            if full = '1' or S_NOC_END_MSG = '1' then
                etat_d <= S_load_addr;
            else
                etat_d <= S_wait_full;
            end if;
            
        when S_load_addr =>
            --on modifie l'addresse du rb si c'est le msg transmis
            -- si c'est le premier message
            if beg_msg_q = '1' then        
                M_IP_WE     <= '1';
                M_IP_ADDR   <= conv_std_logic_vector(unsigned(descript_base_addr_q) + unsigned(descript_write_q) + 4,32);
                M_IP_DATA   <= temp_addr_q;
                temp_addr_d <= temp_addr_q;
--                    temp_addr_d <= conv_std_logic_vector(unsigned(DATA_BASE_ADDR) + unsigned(temp_addr_q), 32); 
            else
                beg_msg_d   <= '0';
            end if;
            etat_d <= S_read_fifo;


        when S_read_fifo =>
            --Lecture de la fifo
            -- Avant, on verifie s'il y a de la place dans la RAM (buffers rx)
            if unsigned(descript_write_q) /= unsigned(descript_read_q xor DESC_SIZE) then
                rd_en   <= '1';  
                etat_d  <= S_load_msg;
            end if;etat_d  <= S_load_msg;
            --irq
                        
       when S_load_msg =>
            if empty = '0' then 
                rd_en       <= '1';
                M_IP_WE     <= '1';
                M_IP_ADDR   <= temp_addr_q;
                M_IP_DATA   <= fifo_out;
                temp_addr_d <= conv_std_logic_vector(unsigned(temp_addr_q) + 4,32);
                size_d      <= conv_std_logic_vector(unsigned(size_q) + 4,32);
            
            else
                rd_en       <= '1';
                M_IP_WE     <= '1';
                M_IP_ADDR   <= temp_addr_q;
                M_IP_DATA   <= fifo_out;
                temp_addr_d <= conv_std_logic_vector(unsigned(temp_addr_q) + 4,32);
                size_d      <= conv_std_logic_vector(unsigned(size_q) + 4,32);
                
                if end_msg_q = '1' then 
                    etat_d <= S_load_size;
                else 
                    etat_d <= S_wait_request;
                end if;
            end if;
            
        when S_load_size =>
                M_IP_WE     <= '1';
                M_IP_ADDR   <= conv_std_logic_vector(unsigned(descript_base_addr_q) + unsigned(descript_write_q),32);
                M_IP_DATA   <= conv_std_logic_vector(unsigned(size_q), 32);
                size_d      <= (others => '0');
                descript_write_d    <= conv_std_logic_vector(unsigned(descript_write_q) + 1,32)and 
                                        conv_std_logic_vector((unsigned(DESC_SIZE & '0')-1),32);
                                        
                temp_addr_d         <= temp_addr_q and conv_std_logic_vector((unsigned(DATA_MEM_SIZE)-1),32);
                
                etat_d <= S_wait_request;
        
    end case;
end process P_COMB;
end Behavioral;
