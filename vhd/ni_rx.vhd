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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ni_rx is
    Port ( 
        CLK     : in  std_logic;
        RESET   : in std_logic;
        --ni_tx_data
        S_NOC_DATA : in std_logic_vector(31 downto 0);
        S_NOC_WE : in std_logic; -- indique le debut et la fin d'une transaction
        S_NOC_END_MSG : in std_logic;
        --irq to uC
        M_irq : out std_logic;
        --local ram's signals
        M_IP_WE   : out std_logic;
        M_IP_RE   : out std_logic;
        M_IP_ADDR : out std_logic_vector(31 downto 0);
        M_IP_DATA : out std_logic_vector(31 downto 0)
    );
end ni_rx;

architecture Behavioral of ni_rx is

    component fifo_rx 
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_en : IN STD_LOGIC;
            rd_en : IN STD_LOGIC;
            dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            full : OUT STD_LOGIC;
            empty : OUT STD_LOGIC
        );
    end component;
    
    type   STATE is (S_init, S_wait_full, S_read_fifo, S_load_ram);
    signal Etat_d, Etat_q   : STATE;
    
    --registers
    signal reg_write_d, reg_write_q : std_logic_vector(31 downto 0);
    signal reg_read_d, reg_read_q   : std_logic_vector(31 downto 0);
    
    signal data_addr_d, data_addr_q : std_logic_vector(31 downto 0) := (others => '0');
    signal addr_offset_d, addr_offset_q : integer := 0; -- offset pour la memoire
    
    --signal fifo
    signal full, empty  : std_logic;
    signal rd_en : std_logic;
    

begin

U_RX_FIFO: fifo_rx 
    port map (
        clk  => CLK,
        rst  => RESET,
        din  => S_NOC_DATA,
        wr_en => S_NOC_WE,
        rd_en => rd_en,
        dout  => M_IP_DATA,
        full  => full,
        empty => empty
    );
---------------------------------------------------------------------------------------
--Process synchrone
P_SYNC: process(CLK, RESET)
begin
    if RESET = '1' then 
        Etat_q          <= S_init;
        reg_read_q      <= (others => '0') ;
        reg_write_q     <= (others => '0') ;
        --data_addr_q     <= (others => '0') ;

     else 
        if CLK'event and CLK = '1' then
            Etat_q          <= Etat_d;
            reg_read_q      <= reg_read_d ;
            reg_write_q     <= reg_write_d ;
            data_addr_q     <= data_addr_d;
            addr_offset_q   <= addr_offset_d;
            
        end if;
     end if;
end process P_SYNC;


---------------------------------------------------------------------------------------
--Process comb
P_COMB: process(Etat_q, reg_read_q, reg_write_q, data_addr_q, addr_offset_q,
                S_NOC_WE, S_NOC_END_MSG,S_NOC_DATA, 
                full, empty)
begin
    --initalisation des siganux (affectation par defaut)
    Etat_d      <= Etat_q;
    reg_write_d <= reg_write_q;
    reg_read_d  <= reg_read_q;
    
    data_addr_d   <= data_addr_q;
    addr_offset_d <= addr_offset_q;
    
    M_irq       <= '0'; -- irq enable;
    M_IP_WE     <= '0';
    M_IP_RE     <= '0';
    M_IP_ADDR   <= (others => '0');

    rd_en <= '0';
    
    case etat_q is
        when S_init =>
            addr_offset_d <= 0; -- initialisation
            --attente de reception de debut de transfert fifo_tx -> fifo_rx             
            if S_NOC_WE = '1' then 
                etat_d <= S_wait_full;
            end if;
            
            
        when S_wait_full => 
            --Attente de remplissage de la fifo par tx
            --on attend soit que a fifo soit pleine ou l'activition de end_msg
            if full = '1' or S_NOC_END_MSG = '1' then 
                etat_d <= S_read_fifo;
            else
                etat_d <= S_wait_full;
            end if;

        when S_read_fifo =>
            --Lecture de la fifo
            rd_en <= '1';  
            etat_d <= S_load_ram;
            
        when S_load_ram =>
            --Ecrire les donnes de la fifo dans la ram local
            
            -- and addr_offset_q /= 64
            if empty = '0' then 
                rd_en <= '1';
                M_IP_WE   <= '1';
                addr_offset_d <= addr_offset_q + 4 ;
                M_IP_ADDR <= std_logic_vector(addr_offset_q + unsigned(data_addr_q));
            
            else
                rd_en <= '1';
                M_IP_WE   <= '1';
                M_IP_ADDR <= std_logic_vector(addr_offset_q + unsigned(data_addr_q));
                
                etat_d <= S_init;
            end if;
            
            
        
    end case;
    
    -- register mapping to memoire
    case reg_write_q is
        when X"00000000" =>
            data_addr_d <= X"00000020";
        when X"00000008" =>
            data_addr_d <= X"00000030";
        when X"00000010" =>
            data_addr_d <= X"00000040";
        when X"00000018" =>    
            data_addr_d <= X"00000050";
        when others => 
            data_addr_d <= X"00000020";
    end case;
        


end process P_COMB;

end Behavioral;
