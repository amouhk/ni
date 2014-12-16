
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;


entity controller is
    Port ( CLK       : in  STD_LOGIC;
           Reset     : in  STD_LOGIC;
           Vsync     : in  STD_LOGIC;
           Href      : in  STD_LOGIC;
           Data_in   : in  STD_LOGIC_VECTOR (7 downto 0);
           PWDN      : out  STD_LOGIC;
           Data_out  : out  STD_LOGIC_VECTOR (7 downto 0);
           we        : out  STD_LOGIC;
           addr      : out  STD_LOGIC_VECTOR (20 downto 0)
			  );
end entity;

architecture Behavioral of controller is
	  component MEM_TEMP
    Port ( CLK        : in  STD_LOGIC;
           RESET      : in  STD_LOGIC;
           D_in_Temp  : in  STD_LOGIC_VECTOR (7 downto 0);
           ADDRt      : in  STD_LOGIC_VECTOR (10 downto 0);
           wet        : in  STD_LOGIC;
           re         : in  STD_LOGIC;
           D_out_Temp : out  STD_LOGIC_VECTOR (7 downto 0)
			 );
end component;

  type   ETAT is (S_init, S_Vsync, S_Href, S_enregistre, S_calcul);
  
  signal etat_q, etat_d         : ETAT;
  signal data_d, data_q         : std_logic_vector(7 downto 0) ;
  signal num_data_d, num_data_q : std_logic ;
  signal cpt_d, cpt_q           : std_logic ;
  signal addr_d, addr_q           : std_logic_vector(20 downto 0);
  signal addr_temp_d, addr_temp_q : std_logic_vector(10 downto 0);
  
  signal wet            : std_logic ;
  signal re             : std_logic ;
  signal deb_page       : std_logic ;

  
  signal d_temp_in  : std_logic_vector (8  downto 0) ;
  signal d_temp_out : std_logic_vector (7  downto 0) ;

begin
	U1 : MEM_TEMP port map (
		CLK          => CLK ,
		RESET        => Reset ,
		D_in_Temp    => d_temp_in(8 downto 1),
		ADDRt        => addr_temp_q ,
		wet          => wet ,
		re           => re,
		D_out_Temp   => d_temp_out
		);


-------------------------------------------------------
	sync : process(clk, RESET)    
	begin
		if (CLK'event and CLK = '0') then
			if RESET = '1' then
				etat_q <= S_init ;
			else 
				etat_q <= etat_d ;
				num_data_q <= num_data_d ;
				data_q <= data_d ;
				cpt_q <= cpt_d ;
				addr_temp_q <= addr_temp_d; 
				addr_q <= addr_d; 
				end if ;
		end if ;
	end process sync ;
	
	
------------------------------------------------------
	comb : process(etat_q, data_q, cpt_q, num_data_q, addr_q, d_temp_out, Vsync, Href, Data_in)
	  variable x_sum : std_logic_vector(8 downto 0); 

	begin
		
		etat_d <= etat_q ;
		num_data_d <= num_data_q ;
		data_d <= data_q ;
		cpt_d <= cpt_q ;
		
		re <= '0';
		wet <= '0';
		we <= '0';
		addr_d <= addr_q;
		addr_temp_d <= addr_temp_q; 

		case etat_q is
			when S_init =>
				cpt_d     <= '0';
				addr_d <= (others => '0');
				addr_temp_d <= (others => '0');
				PWDN <= '0' ;
				
				if Vsync = '1' then
					etat_d <= S_Vsync;
				else
					etat_d <= S_init;
				end if;
				
			when S_Vsync =>
				addr_d <= (others => '0') ;
				deb_page <= '1';
			
				if Vsync = '1' then
					etat_d <= S_Vsync ;
				else
					etat_d <= S_Href ;
				end if;
				
			when S_Href =>
				num_data_d <= '0';
				addr_temp_d <= (others => '0');
				
				if Href = '0' then
					etat_d <= S_Href;
				else
					data_d  <= Data_in ;
					
					if cpt_q = '0' then
						etat_d <= S_enregistre ;
					else
						etat_d <= S_calcul ;
					end if;
				end if;
				
			when S_enregistre =>
				data_d  <= Data_in;
				num_data_d <= not num_data_q;
				
				if num_data_q = '0' then 
					addr_temp_d <= conv_std_logic_vector(unsigned(addr_temp_q) + 1,11);
					d_temp_in <= conv_std_logic_vector(unsigned(Data_in) + unsigned(data_q),9);
					wet  <= '1';
				end if;
						
				if Href = '1' then
					etat_d <=  S_enregistre ;
				else
					etat_d  <=  S_Href ;
					cpt_d <= not cpt_q;
				end if ;
				
			when S_calcul =>
				data_d  <= Data_in;
				num_data_d <= not num_data_q;
				
				if num_data_q = '0' then 
					d_temp_in <= conv_std_logic_vector(unsigned(Data_in) + unsigned(data_q),9);
					addr_temp_d <= conv_std_logic_vector(unsigned(addr_temp_q) + 1, 11);
					re  <= '1';
					x_sum := conv_std_logic_vector(unsigned(d_temp_in(8 downto 1)) + unsigned(d_temp_out), 9);
					Data_out  <= x_sum(8 downto 1);
				end if;
				
				if deb_page = '0' then 
				  if num_data_q = '0' then 
				    addr_d <= conv_std_logic_vector(unsigned(addr_q) + 1,21);
				    we <= '1';
				  end if;
				else
					deb_page <= '0';
				end if;
				
			  addr <= addr_d;
				if Href = '1' then
					 etat_d <=  S_Calcul ;
				else
					 etat_d <=  S_Href ;
					 cpt_d <= not cpt_q;
				end if;
						
		end case;
	end process comb;
	

end Behavioral;
