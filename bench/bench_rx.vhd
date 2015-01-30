----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.12.2014 09:27:42
-- Design Name: 
-- Module Name: bench_ni - Behavioral
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.math_real.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bench_rx is
end bench_rx;

architecture Behavioral of bench_rx is
    component rx
        port (
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
            M_IP_RB         : in  std_logic_vector(31 downto 0);
            --Registres visibles Ã  l'utilisateur
            RB_SIZE         : in std_logic_vector(31 downto 0);
            WRITE           : out std_logic_vector(31 downto 0);
            READ            : in std_logic_vector(31 downto 0)
        );
    end component;
    
    component MEM_RAM
        --generic( MEM_SIZE : integer := 9000 );
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
    
    signal CLK     :  std_logic := '0';
    signal RESET   :  std_logic;
    --ni_tx_data
    signal S_NOC_READY      :  std_logic := '0';
    signal S_NOC_VALID      :  std_logic;
    signal S_NOC_DATA       :  std_logic_vector(31 downto 0) := (others => '0');
    signal S_NOC_WE         :  std_logic := '0'; -- indique le debut et la fin d'une transaction
    signal S_NOC_END_MSG    :  std_logic := '0';
    --irq to uC
    signal M_irq        :  std_logic;
    --local ram's signals
    signal M_IP_WE      :  std_logic ;
    signal M_IP_RE      :  std_logic;
    signal M_IP_ADDR    :  std_logic_vector(31 downto 0);
    signal M_IP_DATA    :  std_logic_vector(31 downto 0):= (others => '0');
    signal M_IP_RB      :  std_logic_vector(31 downto 0):= (others => '0');
      
    signal RB_SIZE    :  std_logic_vector(31 downto 0):= (3 => '1', others => '0');  
    signal READ       :  std_logic_vector(31 downto 0):= (others => '0');
    signal WRITE      :  std_logic_vector(31 downto 0):= (others => '0');
     
    signal we_ram     : std_logic := '0';   
    signal addr_ram   : std_logic_vector(31 downto 0):= (others => '0');   
    signal data_ram   : std_logic_vector(31 downto 0):= (others => '0');
    signal ram_fill_ok: std_logic := '0';
       
    constant clk_demi_period : time := 5 ns;
    signal test_i : integer range 0 to 10 := 10;
begin
u_ram: MEM_RAM
    --generic map (MEM_SIZE => 9000)
    port map(
        CLK     => CLK, 
        RESET   => RESET,
        --port 1
        we      => M_IP_WE,
        re      => M_IP_RE,
        addr    => M_IP_ADDR,
        din     => M_IP_DATA,
        dout    => M_IP_RB,
        --port 2
        we_B    => we_ram,
        re_B    => '0',
        addr_B  => addr_ram,
        din_B   => data_ram,
        dout_B  => open
        
    );

u_rx: rx
    port map (
        CLK         => CLK,
        RESET       => RESET,
        --ni_tx_data
        S_NOC_READY => S_NOC_READY,
        S_NOC_VALID => S_NOC_VALID,
        S_NOC_DATA  => S_NOC_DATA,
        S_NOC_WE    => S_NOC_WE,
        S_NOC_END_MSG => S_NOC_END_MSG,
        --irq to uC
        M_irq  => M_irq,
        --local ram's signals
        M_IP_WE     => M_IP_WE,
        M_IP_RE     => M_IP_RE,
        M_IP_ADDR   => M_IP_ADDR,
        M_IP_DATA   => M_IP_DATA,
        M_IP_RB     => M_IP_RB,
        --Registres visibles a l'utilisateur
        RB_SIZE     => RB_SIZE,
        WRITE       => WRITE,
        READ        => READ
    );

    CLK <= not(CLK) after clk_demi_period;
    RESET <=  '1', '0' after 10*clk_demi_period;


-------------------------------------------------------------------------
--Remplissage du rb (address)
-------------------------------------------------------------------------
fill_ram: process
begin
    wait until RESET = '0' and RESET'event;
    -- On remplit le RB addresse
    -- data_ram commence à 128 au lieu de 64
    for i in 0 to 7 loop
        we_ram <= '1';
        data_ram <= conv_std_logic_vector(128 + (1024 * i), 32);
        addr_ram <= conv_std_logic_vector(8*i + 4, 32);
        wait for clk_demi_period;
        
        we_ram <= '0';
        wait for clk_demi_period;
    end loop;
    --fin du remplissage
    we_ram <= '0';
    data_ram <= (others => '0');
    addr_ram <= (others => '0');
    ram_fill_ok <= '1';
    -- arret du process
    wait on RESET;
end process fill_ram;

-----------------------------------------------------------------------
--Choix de Test i
-----------------------------------------------------------------------
p_test_i: process
begin
    wait until RESET'event and RESET = '0';
    wait for 80*clk_demi_period;
    test_i <= 0;
    wait until M_irq'event and M_irq = '1';
    wait for 65*clk_demi_period;
    test_i <= test_i + 1;
    wait until M_irq'event and M_irq = '1';
    wait for 35*clk_demi_period;
    test_i <= test_i + 1;
    wait until M_irq'event and M_irq = '1';
    wait for 25*clk_demi_period;
    test_i <= test_i + 1;
    
    wait on RESET;
end process p_test_i;
-------------------------------------------------------------------------
--Process de simulation du NI_TX
-------------------------------------------------------------------------
p_ready: process
begin      
    wait for 100*clk_demi_period;
    S_NOC_READY <= '1';
    wait for 4*clk_demi_period;
    S_NOC_READY <= '0';
end process;
-----------------------------------------------------------------------
--Simulation des data venant de la fifo_tx
-----------------------------------------------------------------------
p_fifo_tx: process
    variable j : integer := 0;
begin
    wait until S_NOC_VALID = '1';
    for i in 0 to 150 loop
        case test_i is -- state est la variable du choix
            when 0 => -- remplir un portion de fifo puis end_msg
                if i >= 6 then 
                    S_NOC_DATA <= (others => '1');
                    S_NOC_WE <= '0';
                    S_NOC_END_MSG <= '0';
                    
                else
                    S_NOC_DATA <= conv_std_logic_vector(i, 32);
                    S_NOC_WE <= '1';
                    if i = 5 then S_NOC_END_MSG <= '1'; end if;
                    wait for 2*clk_demi_period;
                end if;
                
            when 1 => -- 16mots(fifo entiere) puis end_msg
                if i >= 16 then 
                    S_NOC_DATA <= (others => '1');
                    S_NOC_WE <= '0';
                    S_NOC_END_MSG <= '0';
                else
                    S_NOC_DATA <= conv_std_logic_vector(i, 32);
                    S_NOC_WE <= '1';
                    if i = 15 then S_NOC_END_MSG <= '1'; end if;
                    wait for 2*clk_demi_period;
                end if;
            
            when 2 => -- 256mots puis end_msg
                loop
                    if j = 16 then
                        S_NOC_WE <= '0';
                        j := 0;
                        S_NOC_END_MSG <= '0';
                        wait for 74*clk_demi_period;
                    else
                        S_NOC_DATA <= conv_std_logic_vector(j, 32);
                        S_NOC_WE <= '1';
                        wait for 2*clk_demi_period;
                        j := j+1;
                        if i = 15 then S_NOC_END_MSG <= '1'; end if;
                    end if;
                    --j := j+1;
                end loop;
            when 3 => -- 256mots puis end_msg
                null;
            when others => null;    
        end case;
    end loop;
    S_NOC_WE <= '0';
end process p_fifo_tx;
            
--            when 2 => -- 256mots puis end_msg
            
--                for j in 0 to 15 loop
--                    S_NOC_DATA <= conv_std_logic_vector(i*j+j, 32);
--                    S_NOC_WE <= '1';
--                    wait for 2*clk_demi_period;
--                    if i = 15 then
--                        if j=14 then 
--                           S_NOC_END_MSG <= '1'; 
--                        else
--                            S_NOC_END_MSG <= '0'; 
--                        end if;
--                    end if;
--                end loop;

--                S_NOC_WE <= '0';
--                wait for 64*clk_demi_period;
----            when 3 =>
            
----            when 3 =>
            
----            when 3 =>
                
-----------------------------------------------------------------------
--Process de simulation du NI_TX
--le message se trouve dans une seule barette de 16 mots
-------------------------------------------------------------------------
--long_msg_test: process 
--begin 
--    --for j in 1 to 144 loop
--        wait until S_NOC_VALID = '1';   
--        for i in 0 to 15 loop
--            S_NOC_DATA <= conv_std_logic_vector(i, 32);
--            S_NOC_WE <= '1';
--            wait for 2*clk_demi_period;
--        end loop;
        
--        S_NOC_WE <= '0';
--        wait for 42*clk_demi_period;
--    --end loop;
--end process;            




--ajout de end_of_msg en milieu d'un barette
--end_msg_test: process 
--begin 
--    for j in 1 to 144 loop
--        wait until S_NOC_VALID = '1';
           
--        for i in 0 to 15 loop
--            if j = 24 then 
--                S_NOC_END_MSG <= '1';
--            else
--                S_NOC_END_MSG <= '0';
--            end if;
--            S_NOC_DATA <= conv_std_logic_vector(i, 32);
--            S_NOC_WE <= '1';
--            wait for 2*clk_demi_period;
--        end loop;
        
--        S_NOC_WE <= '0';
--        wait for 42*clk_demi_period;
--   end loop;
--end process;
-----------------------------------------------------------------------
--ajout de end_of_msg pour une fifo non pleine.
--end_msg_test: process 
--begin 

--        wait until S_NOC_VALID = '1';    
--        for i in 0 to 15 loop
--            if i = 10 then 
--                S_NOC_END_MSG <= '1';
--            else 
--                S_NOC_END_MSG <= '0';
--            end if;
--            S_NOC_DATA <= conv_std_logic_vector(i, 32);
--            S_NOC_WE <= '1';
--            wait for 2*clk_demi_period;
--        end loop;
        
--        S_NOC_WE <= '0';
--        wait for 42*clk_demi_period;
--end process;
-----------------------------------------------------------------------
-- Simulation du cpu
-----------------------------------------------------------------------
cpu_write_process: process
begin 
    --wait for 100 us;
    for k in 0 to 7 loop
    wait for 100 us;
        READ <= conv_std_logic_vector(k*8, 32);
        
    end loop;
end process;

end Behavioral;
