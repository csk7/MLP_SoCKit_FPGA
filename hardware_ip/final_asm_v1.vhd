------CODE FOR REGISTER------
--------------------------------------------------------------------------------- 
-- Engineer: C Sivakumar
-- 
-- Create Date:    08:37:44 05/25/2016 
-- Design Name:    register
-- Module Name:    reg_v1-behavioral
-- Project Name:   Tapped Delay Line
-- Revision 0.01 - File Created
-- Additional Comments: no load signal
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
LIBRARY lpm; 
USE lpm.lpm_components.all; 

entity final_asm_v1 is
port(
		av_clock:in std_logic;
		av_reset:in std_logic;
				
		avs_readdata:out std_logic_vector(63 DOWNTO 0);
		avs_read:in std_logic;
		
		avs_writedata:in std_logic_vector(63 downto 0);
      avs_address: in std_logic_vector(4 downto 0);
		avs_write: in std_logic; 
		avs_waitrequest: out std_logic;
		avs_byteenable:in std_logic_vector(7 downto 0);
	  --a_out:out std_logic_vector(LOG_BITS-1 downto 0);
	  
	   av_writedata:out std_logic_vector(127 downto 0);
		av_write:out std_logic;
		
	   av_address:out std_logic_vector(31 downto 0);
		av_byteenable:out std_logic_vector(15 downto 0);
		av_readdata:in std_logic_vector(127 downto 0);
		av_read:out std_logic;
		av_waitrequest:in std_logic);
    
end final_asm_v1;


architecture Behavioral of final_asm_v1 is


signal start :std_logic_vector(63 downto 0):=(others => '0');
signal done_main:std_logic:='0';





signal stats:std_logic_vector(4 downto 0);


type state is (INIT, READ_SOURCE,IDLE_SOURCE,POP_WAIT_SOURCE,POP_SOURCE, N0_CHECK_LAYERS,SET_PARAMETERS,N1_CHECK_NEURONS,READ_BIAS,IDLE_BIAS,POP_WAIT_BIAS,POP_BIAS,SET_ACC,N2_CHECK_INPUTS,READ_WEIGHT,IDLE_WEIGHT,POP_WAIT_WEIGHT,POP_WEIGHT,CALCUL,UPDATE_CUR_INP,COMPARISON,UPDATE_CUR_NEUR,PUSH_WAIT_RES,PUSH_RES,WRITE_RES,IDLE_RES,EXITING);
signal current_state: state;


---counting signals


signal current_layer:std_logic_vector(2 downto 0);  --varies from 0 to 2
signal current_neuron:std_logic_vector(10 downto 0);  --varies from 0 to 1023
signal current_input:std_logic_vector(10 downto 0);  --varies from 0 to 1023

signal c_s_r:std_logic_vector(10 downto 0):=(others => '0');  --varies from 0 to 256
signal c_s_p:std_logic_vector(10 downto 0):=(others => '0');  --varies from 0 to 256
signal c_w_r:std_logic_vector(20 downto 0);
signal c_w_p:std_logic_vector(4 downto 0);
signal count_local_weight:std_logic_vector(4 downto 0);
signal c_res_p:std_logic_vector(10 downto 0);
signal c_res_w:std_logic_vector(10 downto 0);



----avalon slave registers
signal reg_slave_source_address1:std_logic_vector(63 downto 0):=x"0000008000000080";
signal reg_slave_value_address1:std_logic_vector(63 downto 0):=x"0000002800000020";

signal reg_slave_n_neurons1:std_logic_vector(63 downto 0):=x"0000000200000005";
signal reg_slave_n_inputs1:std_logic_vector(63 downto 0):=x"0000000500000010";
signal reg_slave_p_threshhold1:std_logic_vector(63 downto 0):=x"0000000200000002";
signal reg_slave_n_threshhold1:std_logic_vector(63 downto 0):=x"0000002000000002";
signal reg_slave_bias_address1:std_logic_vector(63 downto 0):=x"0000008000000000";
signal reg_slave_weight_address1:std_logic_vector(63 downto 0):=x"0000002800000020";




signal reg_slave_n_neurons2:std_logic_vector(63 downto 0):=x"0000000200000005";
signal reg_slave_n_inputs2:std_logic_vector(63 downto 0):=x"0000000500000010";
signal reg_slave_p_threshhold2:std_logic_vector(63 downto 0):=x"0000000200000002";
signal reg_slave_n_threshhold2:std_logic_vector(63 downto 0):=x"0000002000000002";
signal reg_slave_bias_address2:std_logic_vector(63 downto 0):=x"0000008000000000";
signal reg_slave_weight_address2:std_logic_vector(63 downto 0):=x"0000002800000020";

signal reg_slave_n_neurons3:std_logic_vector(63 downto 0):=x"0000000200000005";
signal reg_slave_n_inputs3:std_logic_vector(63 downto 0):=x"0000000500000010";
signal reg_slave_p_threshhold3:std_logic_vector(63 downto 0):=x"0000000200000002";
signal reg_slave_n_threshhold3:std_logic_vector(63 downto 0):=x"0000002000000002";
signal reg_slave_bias_address3:std_logic_vector(63 downto 0):=x"0000008000000000";
signal reg_slave_weight_address3:std_logic_vector(63 downto 0):=x"0000002800000020";

---registers to store intermediate values

type reg_source_t is array(255 downto 0) of std_logic_vector(31 downto 0);
type reg_weight_t is array(15 downto 0) of std_logic_vector(31 downto 0);
type reg_bias_t is array(1023 downto 0) of std_logic_vector(31 downto 0);
type reg_result_t is array(1023 downto 0) of std_logic_vector(1 downto 0);



signal reg_source:reg_source_t;
signal reg_weight:reg_weight_t;
signal reg_bias:reg_bias_t;
signal reg_result,reg_result2:reg_result_t:=(others => (others =>'0'));


type reg_n_neurons_t is array(3 downto 0) of std_logic_vector(10 downto 0); 
type reg_n_inputs_t is array(3 downto 0) of std_logic_vector(10 downto 0); 
type reg_p_threshhold_t is array(3 downto 0) of std_logic_vector(31 downto 0); 
type reg_n_threshhold_t is array(3 downto 0) of std_logic_vector(31 downto 0); 
type reg_bias_address_t is array(3 downto 0) of std_logic_vector(31 downto 0);
type reg_weights_address_t is array(3 downto 0) of std_logic_vector(31 downto 0); 
signal reg_av_source_address:std_logic_vector(31 downto 0):=(others => '0');
signal reg_av_address_value:std_logic_vector(31 downto 0);

signal reg_n_neurons :reg_n_neurons_t;
signal reg_n_inputs :reg_n_inputs_t;
signal reg_p_threshhold :reg_p_threshhold_t;
signal reg_n_threshhold :reg_n_threshhold_t;
signal reg_bias_address :reg_bias_address_t;
signal reg_weights_address :reg_weights_address_t;



--registers for current asm

signal n_neurons:std_logic_vector(10 downto 0):="01000000000";
signal n_inputs:std_logic_vector(10 downto 0):="00000000000";
signal reg_av_address_bias:std_logic_vector(31 downto 0);
signal reg_av_address_weight:std_logic_vector(31 downto 0);
signal p_threshhold:std_logic_vector(31 downto 0);
signal n_threshhold:std_logic_vector(31 downto 0);




signal reg_av_address:std_logic_vector(31 downto 0);
signal n_layers:std_logic_vector(2 downto 0):="011";
signal acc:std_logic_vector(127 downto 0);

---- mult and acc values registers

shared variable mul1,mul2,mul3, mul4, mul5, mul6, mul7, mul8 : std_logic_vector(16 downto 0):=(others =>'0');
shared variable kmap_res8,kmap_res7,kmap_res6,kmap_res5,kmap_res4,kmap_res3,kmap_res2,kmap_res1: std_logic_vector(1 downto 0):=(others =>'0');
shared variable temp11,temp12,temp21,temp22,temp31,temp32,temp41,temp42,temp51,temp52,temp61,temp62,temp71,temp72,temp81,temp82:std_logic:='0';


--default number registers

signal db_zero:std_logic_vector(1 downto 0):="00";
signal one:std_logic_vector(1 downto 0):="01";
signal two:std_logic_vector(3 downto 0):="0010";
signal three:std_logic_vector(3 downto 0):="0011";
signal four:std_logic_vector(3 downto 0):="0100";
signal five:std_logic_vector(3 downto 0):="0101";
signal six:std_logic_vector(3 downto 0):="0110";
signal seven:std_logic_vector(3 downto 0):="0111";
signal eight:std_logic_vector(4 downto 0):="01000";

---fifo----

signal fifo_in_input:std_logic_vector(127 downto 0):=(others =>'0');
signal fifo_in_write_req:std_logic;
signal fifo_in_read_req:std_logic;
signal fifo_in_output:std_logic_vector(127 downto 0);
signal fifo_in_usedw:std_logic_vector(7 downto 0);
signal fifo_in_full:std_logic;
signal fifo_in_empty:std_logic;

signal fifo_mr_input:std_logic_vector(127 downto 0):=(others =>'0');
signal fifo_mr_write_req:std_logic:='0';
signal fifo_mr_read_req:std_logic;
signal fifo_mr_output:std_logic_vector(127 downto 0);
signal fifo_mr_usedw:std_logic_vector(7 downto 0);
signal fifo_mr_full:std_logic;
signal fifo_mr_empty:std_logic;


----avalon slave interface---
signal done_wr:std_logic;



	begin

	FIFO_READ:	LPM_FIFO_DC
		generic map (
			LPM_WIDTH => 128,
			LPM_WIDTHU => 8,
			LPM_NUMWORDS => 256,
			LPM_SHOWAHEAD => "ON"
		)

	port map (
		DATA => fifo_in_input,
		WRCLOCK => av_clock,
		RDCLOCK => av_clock,
		WRREQ => fifo_in_write_req,
		RDREQ => fifo_in_read_req,
		ACLR => av_reset,
		Q => fifo_in_output,
		WRUSEDW => fifo_in_usedw,
      WRFULL => fifo_in_full,
      RDEMPTY => fifo_in_empty
	);
	
	FIFO_WRITE:	LPM_FIFO_DC
		generic map (
			LPM_WIDTH => 128,
			LPM_WIDTHU => 8,
			LPM_NUMWORDS => 256,
			LPM_SHOWAHEAD => "ON"
		)

	port map (
		DATA => fifo_mr_input,
		WRCLOCK => av_clock,
		RDCLOCK => av_clock,
		WRREQ => fifo_mr_write_req,
		RDREQ => fifo_mr_read_req,
		ACLR => av_reset,
		Q => fifo_mr_output,
		WRUSEDW => fifo_mr_usedw,
      WRFULL => fifo_mr_full,
      RDEMPTY => fifo_mr_empty
	);
	
----AVALON SLAVE READ-----	
process(av_clock,av_reset)
begin
 if av_reset='1' then                                 
  reg_slave_source_address1<=(others=>'0');
  reg_slave_n_inputs1<=(others=>'0');
 elsif av_clock='1' and av_clock'event then          
   if (avs_write = '1') then
	 case avs_address is
		  when "00000" =>
			   reg_slave_n_neurons1 <= avs_writedata;
				
        when "00001" =>
				reg_slave_n_neurons2 <= avs_writedata;
			 
		  when "00010" =>
				reg_slave_n_inputs1 <= avs_writedata;
			 	 
        when "00011" =>
				reg_slave_n_inputs2 <= avs_writedata;
			
        when "00100" =>
				reg_slave_p_threshhold1 <= avs_writedata;
			 
        when "00101" =>
				reg_slave_p_threshhold2 <= avs_writedata;
			 
        when "00110" =>
				reg_slave_n_threshhold1 <= avs_writedata;
			 
        when "00111" =>
				reg_slave_n_threshhold2 <= avs_writedata;
			 
		  when "01000" =>
			   reg_slave_source_address1 <= avs_writedata;
				
        when "01001" =>
			   reg_slave_value_address1 <= avs_writedata;
			 
		  when "01010" =>
			 	reg_slave_bias_address1 <= avs_writedata;
				 
        when "01011" =>
			    reg_slave_weight_address1 <= avs_writedata;	
				  
        when "01100" =>
			    reg_slave_bias_address2 <= avs_writedata;
			 
        when "01101" =>
			    reg_slave_weight_address2 <= avs_writedata;	
        
		  when "01110" =>
			    reg_slave_bias_address3 <= avs_writedata;
				 
        when "01111" =>
			    reg_slave_weight_address3 <= avs_writedata;	
   		  
        when "10000" =>
             start <= avs_writedata;		  
		  
		  when "10001" =>
			   reg_slave_n_neurons3 <= avs_writedata;
		  
		  when "10010" =>
			   reg_slave_n_inputs3 <= avs_writedata;
		  
		  when "10011" =>
			   reg_slave_p_threshhold3 <= avs_writedata;
		 
		  when "10100" =>
			   reg_slave_n_threshhold3 <= avs_writedata;
		
		when others => null;
	 end case;
	end if; 
 end if;
end process;


process(avs_write,done_wr)
	begin
		if (avs_write = '1' and done_wr = '1') then
			avs_waitrequest <='1';
		else
			avs_waitrequest <='0';
		end if;
end process;
 
-----AVALON SLAVE WRITE----
process (avs_read,reg_slave_source_address1, done_main, reg_source,reg_av_address,avs_address,n_inputs,n_neurons,n_layers,current_input,current_neuron, reg_p_threshhold,reg_av_source_address,current_layer,p_threshhold,stats,reg_n_neurons,reg_av_address_bias,reg_av_address_weight,reg_bias,n_threshhold,reg_result,reg_result2)
begin
	  if (avs_read = '1') then
		 case avs_address is
			when "00000" =>
				avs_readdata <= reg_slave_source_address1;
			when "00001" =>	
				   avs_readdata <= std_logic_vector(resize(signed(n_inputs),64));
			when "00010" =>
					avs_readdata <= std_logic_vector(resize(signed(n_neurons),64));
			when "00011" =>
					avs_readdata <= std_logic_vector(resize(signed(n_layers),64));
			when "00100" =>
				avs_readdata <= std_logic_vector(resize(unsigned(current_input),64));
			when "00101" =>	
				   avs_readdata <= std_logic_vector(resize(unsigned(current_neuron),64));
			when "00110" =>
					avs_readdata <= std_logic_vector(resize(unsigned(current_layer),64));
			when "00111" =>
					avs_readdata <= std_logic_vector(resize(unsigned(p_threshhold),64));        			
			when "01000" =>
				avs_readdata <= std_logic_vector(resize(unsigned(stats),64));
			when "01001" =>	
				   avs_readdata <= std_logic_vector(resize(unsigned(reg_source(17)),64));
			when "01010" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_source(0)),64));
			when "01011" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_n_neurons(0)),64));
			when "01100" =>	
				   avs_readdata <= std_logic_vector(resize(signed(reg_n_neurons(1)),64));
			when "01101" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_n_neurons(2)),64));
			when "01110" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_p_threshhold(0)),64));
			when "01111" =>	
				   avs_readdata <= std_logic_vector(resize(signed(reg_p_threshhold(1)),64));
			when "10000" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_p_threshhold(2)),64));
			when "10001" =>	
				   avs_readdata <= std_logic_vector(resize(signed(reg_source(3)),64));
			when "10010" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_source(63)),64));					
			when "10011" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_av_source_address),64));
			when "10100" =>	
				   avs_readdata <= std_logic_vector(resize(signed(reg_av_address),64));
			when "10101" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_av_address_bias),64));
			when "10110" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_av_address_weight),64));
			when "10111" =>	
				   avs_readdata <= std_logic_vector(resize(signed(n_threshhold),64));
			when "11000" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_bias(0)),64));
			when "11001" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_bias(1)),64));
			when "11010" =>	
				   avs_readdata <= std_logic_vector(resize(signed(reg_result(4)),64));
			when "11011" =>
					avs_readdata <= std_logic_vector(resize(signed(reg_result2(4)),64));						
			when "11100" =>
					avs_readdata <= x"000000000000000" & "000" & done_main;					
				
	
			when others => avs_readdata <= (others => '0'); 
		 end case;
	  else
		  avs_readdata <= (others => '0');
	  end if;  
end process;



------MANY READS------
process(av_clock,av_reset)
begin
	if (av_reset = '1') then
		current_state <= INIT;
	elsif (av_clock='1' and av_clock'event) then
		case current_state is
			when INIT =>
				if(start(0)= '1') then
				    current_state <= READ_SOURCE;
					 c_s_r <= "00000000000"; 

					   					
						reg_n_neurons(0) <= reg_slave_n_neurons1(10 downto 0);
						reg_n_neurons(1) <= reg_slave_n_neurons2(10 downto 0);
						reg_n_neurons(2) <= reg_slave_n_neurons3(10 downto 0);
						reg_n_neurons(3) <= (others => '0');
						
						reg_n_inputs(0) <= reg_slave_n_inputs1(10 downto 0);
						reg_n_inputs(1) <= reg_slave_n_inputs2(10 downto 0);
						reg_n_inputs(2) <= reg_slave_n_inputs3(10 downto 0);
						reg_n_inputs(3) <= (others => '0');
						
						reg_p_threshhold(0) <= reg_slave_p_threshhold1(31 downto 0);
						reg_p_threshhold(1) <= reg_slave_p_threshhold2(31 downto 0);
						reg_p_threshhold(2) <= reg_slave_p_threshhold3(31 downto 0);
						reg_p_threshhold(3) <= (others => '0');
						
						reg_n_threshhold(0) <= reg_slave_n_threshhold1(31 downto 0);
						reg_n_threshhold(1) <= reg_slave_n_threshhold2(31 downto 0);
						reg_n_threshhold(2) <= reg_slave_n_threshhold3(31 downto 0);
						reg_n_threshhold(3) <= (others => '0');
						
						reg_bias_address(0) <= reg_slave_bias_address1(31 downto 0);
						reg_bias_address(1) <= reg_slave_bias_address2(31 downto 0);
						reg_bias_address(2) <= reg_slave_bias_address3(31 downto 0);
						reg_bias_address(3) <= (others => '0');
						
						reg_weights_address(0) <= reg_slave_weight_address1(31 downto 0);
						reg_weights_address(1) <= reg_slave_weight_address2(31 downto 0);
						reg_weights_address(2) <= reg_slave_weight_address3(31 downto 0);
						reg_weights_address(3) <= (others => '0');
						
						reg_av_source_address <= reg_slave_source_address1(31 downto 0);	
						n_inputs <= reg_slave_n_inputs1(10 downto 0);
						done_main <= '0';
					 	
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');

					 else				
			       current_state <= INIT;
						
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');	
				      done_main<='0';	 					 
				end if;
				stats <="00000";	
				
			when READ_SOURCE =>		
					if (c_s_r < n_inputs) then 
						current_state <= IDLE_SOURCE;
						
						
						---master read signals
						av_address <= std_logic_vector(unsigned (reg_av_source_address(31 downto 0)) + unsigned(unsigned(c_s_r) & unsigned (db_zero)));   
				      av_byteenable <= (others => '1' ); 
				      av_read  <= '1'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');							
								           				
							
					else
						current_state <= POP_SOURCE;
						c_s_p <= "00000000000";
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');						
						
					end if;
					stats <="00001";
					
			when IDLE_SOURCE =>		
					if (av_waitrequest = '0') then 
						current_state <= READ_SOURCE;
						c_s_r <= std_logic_vector(unsigned(c_s_r) + unsigned(four));
						

						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='1';  
						fifo_in_input  <= av_readdata;
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');						
					else 
				      current_state <= IDLE_SOURCE;	
						
					end if;
					stats <="00010";
					
	      when POP_WAIT_SOURCE =>
			       c_s_p <= std_logic_vector(unsigned(c_s_p) + unsigned(four));
					 current_state <= POP_SOURCE;
					 ---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');	
	            							
					
			when POP_SOURCE =>		
					
					if (c_s_p < n_inputs) then 
                current_state <= POP_WAIT_SOURCE;
					
					reg_source(to_integer(unsigned(c_s_p))) <= fifo_in_output(31 downto 0);
					reg_source(to_integer(unsigned(c_s_p) +unsigned(one))) <= fifo_in_output(63 downto 32);
					reg_source(to_integer(unsigned(c_s_p) + unsigned(two))) <= fifo_in_output(95 downto 64);
					reg_source(to_integer(unsigned(c_s_p) + unsigned(three))) <= fifo_in_output(127 downto 96);
					
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '1'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');	
	
                else
						current_state <= N0_CHECK_LAYERS;
			         current_layer <= "000"; 
					   c_w_r <= "000000000000000000000";
						
						
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');							 
					 end if;	 
												
					stats <="00011";
																
					
			when N0_CHECK_LAYERS =>		
					if (current_layer < n_layers) then 
						current_state <= SET_PARAMETERS;
		            
						for i in 0 to 1023 loop
							reg_result(i) <= reg_result2(i); 
						end loop;
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');	
						
					else
						current_state <= PUSH_RES;
						c_res_p <= "00000000000";
                  reg_av_address_value <= reg_slave_value_address1(31 downto 0);
						
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');	
	
												
					end if;
					stats<="00100";
					
		   when SET_PARAMETERS =>		
					
						current_state <= N1_CHECK_NEURONS;
						current_neuron <= "00000000000";
						
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');	
						
						n_neurons <=reg_n_neurons(to_integer(unsigned(current_layer)));
						n_inputs <=reg_n_inputs(to_integer(unsigned(current_layer)));
						p_threshhold <=reg_p_threshhold(to_integer(unsigned(current_layer)));
						n_threshhold <=reg_n_threshhold(to_integer(unsigned(current_layer)));
						reg_av_address_bias <=reg_bias_address(to_integer(unsigned(current_layer)));
						reg_av_address_weight <=reg_weights_address(to_integer(unsigned(current_layer)));						
               stats<="00101";
					
			when N1_CHECK_NEURONS =>		
					if (current_neuron < n_neurons) then 
						  current_state <= READ_BIAS;
						  
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');						  
					else
						current_state <= N0_CHECK_LAYERS;
						current_layer <= std_logic_vector(unsigned(current_layer) + unsigned(one));
						c_w_r <= "000000000000000000000";
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');	
						
					end if;
				stats<="00110";	
					
			when READ_BIAS =>		
					if (current_neuron(1 downto 0) = "00") then 
						current_state <= IDLE_BIAS;

						---master read signals
						av_address <= std_logic_vector(unsigned(reg_av_address_bias) + unsigned(unsigned(current_neuron) & unsigned(db_zero)));
				      av_byteenable <= (others => '1'); 
				      av_read  <= '1'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');	
						
					else
						current_state <= SET_ACC;
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');					
						
					end if;
			  stats<="00111";	
				
			when IDLE_BIAS =>		
					if (av_waitrequest = '0') then 
                  current_state <= POP_WAIT_BIAS;					
					
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='1';  
						fifo_in_input  <= av_readdata;
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');					
						
					else
						current_state <= IDLE_BIAS;
					
					end if;
			  stats<="01000";
			  
			when POP_WAIT_BIAS =>
	               current_state <= POP_BIAS;
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');						
			         stats<="01001";
			  
	      when POP_BIAS =>		 
						current_state <= SET_ACC;
						
						reg_bias(0) <= fifo_in_output(31 downto 0);
						reg_bias(1) <= fifo_in_output(63 downto 32);
						reg_bias(2) <= fifo_in_output(95 downto 64);
						reg_bias(3) <= fifo_in_output(127 downto 96);	
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '1'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');						
						
			   stats<="01010";
				
			when SET_ACC =>
	               current_state <=N2_CHECK_INPUTS;
						current_input <= "00000000000";
        	         acc(127 downto 32)<=(others =>'0');
						acc(31 downto 0)<= reg_bias(to_integer(unsigned(n_neurons(1 downto 0))));
					   ---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');						
						
						
			stats<="01011";			
					
			when N2_CHECK_INPUTS =>		
					if (current_input < n_inputs) then 
						current_state <= READ_WEIGHT;
						count_local_weight <= "00000";
					 ---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');						
					else
						current_state <= COMPARISON;
					 ---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');					
					end if;
		   stats<="01100";
		
		
			when READ_WEIGHT =>		
					if (count_local_weight < "01000") then 
						current_state <= IDLE_WEIGHT;
						
						---master read signals
						av_address <= std_logic_vector(unsigned(reg_av_address_weight) + unsigned(unsigned(c_w_r) & unsigned(db_zero)));	
				      av_byteenable <= (others => '1' ); 
				      av_read  <= '1'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');	
	
					else
						current_state <= POP_WEIGHT;
						
					   c_w_p <= "00000";
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');					
						
					end if;
			stats<="01101";		
					
			when IDLE_WEIGHT =>		
					if (av_waitrequest = '0') then 
						current_state <= READ_WEIGHT;
						c_w_r <= std_logic_vector(unsigned(c_w_r) + unsigned (four));
						count_local_weight <= std_logic_vector(unsigned(count_local_weight) + unsigned (four));
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0';
				      fifo_in_write_req <='1';  
						fifo_in_input  <= av_readdata;
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');						
						
					else
						current_state <= IDLE_WEIGHT;
						
					end if;
			stats<="01110";
			
			when POP_WAIT_WEIGHT =>
                current_state <= POP_WEIGHT;
					 c_w_p <= std_logic_vector(unsigned(c_w_p) + unsigned (four));					 
					 ---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');					
			    stats<="01111";
			
			when POP_WEIGHT =>		
					if (c_w_p < std_logic_vector(unsigned(eight))) then 
						current_state <= POP_WAIT_WEIGHT;

						reg_weight(to_integer(unsigned(c_w_p))) <=fifo_in_output(31 downto 0);
						reg_weight(to_integer(unsigned(c_w_p) + unsigned(one))) <=fifo_in_output(63 downto 32);
						reg_weight(to_integer(unsigned(c_w_p) + unsigned(two))) <=fifo_in_output(95 downto 64);
						reg_weight(to_integer(unsigned(c_w_p) + unsigned(three))) <=fifo_in_output(127 downto 96);

						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '1'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');							
						
					else
						current_state <= CALCUL;
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');							
					end if;
			stats<="10000";
			
			when CALCUL =>		
					if (current_layer = "000") then 
						current_state <= UPDATE_CUR_INP;
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');
						
						mul1 := std_logic_vector(signed(reg_source(to_integer(unsigned(current_input)))(8 downto 0)) * signed(reg_weight(0)(7 downto 0)));
						mul2 := std_logic_vector(signed(reg_source(to_integer(unsigned(current_input) + unsigned(one)))(8 downto 0)) * signed(reg_weight(1)(7 downto 0)));
						mul3 := std_logic_vector(signed(reg_source(to_integer(unsigned(current_input) + unsigned(two)))(8 downto 0)) * signed(reg_weight(2)(7 downto 0)));
						mul4 := std_logic_vector(signed(reg_source(to_integer(unsigned(current_input) + unsigned(three)))(8 downto 0)) * signed(reg_weight(3)(7 downto 0)));
						mul5 := std_logic_vector(signed(reg_source(to_integer(unsigned(current_input) + unsigned(four)))(8 downto 0)) * signed(reg_weight(4)(7 downto 0)));
						mul6 := std_logic_vector(signed(reg_source(to_integer(unsigned(current_input) + unsigned(five)))(8 downto 0)) * signed(reg_weight(5)(7 downto 0)));
						mul7 := std_logic_vector(signed(reg_source(to_integer(unsigned(current_input) + unsigned(six)))(8 downto 0)) * signed(reg_weight(6)(7 downto 0)));						
						mul8 := std_logic_vector(signed(reg_source(to_integer(unsigned(current_input) + unsigned(seven)))(8 downto 0)) * signed(reg_weight(7)(7 downto 0)));
						
						acc <= std_logic_vector(signed(acc) + signed (mul1) + signed (mul2) + signed (mul3) + signed (mul4) + signed (mul5) + signed (mul6) + signed (mul7) + signed (mul8));						
						
					else
						current_state <= UPDATE_CUR_INP;

						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');
						
						kmap_res1(0) := reg_result(to_integer(unsigned(current_input)))(0) and reg_weight(0)(0);
						kmap_res2(0) := reg_result(to_integer(unsigned(current_input) + unsigned(one)))(0) and reg_weight(1)(0);
						kmap_res3(0) := reg_result(to_integer(unsigned(current_input) + unsigned(two)))(0) and reg_weight(2)(0);
						kmap_res4(0) := reg_result(to_integer(unsigned(current_input) + unsigned(three)))(0) and reg_weight(3)(0);
						kmap_res5(0) := reg_result(to_integer(unsigned(current_input) + unsigned(four)))(0) and reg_weight(4)(0);
						kmap_res6(0) := reg_result(to_integer(unsigned(current_input) + unsigned(five)))(0) and reg_weight(5)(0);
						kmap_res7(0) := reg_result(to_integer(unsigned(current_input) + unsigned(six)))(0) and reg_weight(6)(0);
						kmap_res8(0) := reg_result(to_integer(unsigned(current_input) + unsigned(seven)))(0) and reg_weight(7)(0);
						
						
						temp11 := (not(reg_result(to_integer(unsigned(current_input)))(1)) and reg_result(to_integer(unsigned(current_input)))(0) and reg_weight(0)(0) and reg_weight(0)(1));
					   temp12 := (reg_result(to_integer(unsigned(current_input)))(1) and reg_result(to_integer(unsigned(current_input)))(0) and not(reg_weight(0)(1))  and reg_weight(0)(0));
					   
						temp21 := (not(reg_result(to_integer(unsigned(current_input) + unsigned(one)))(1)) and reg_result(to_integer(unsigned(current_input) + unsigned(one)))(0) and reg_weight(1)(0) and reg_weight(1)(1));
					   temp22 := (reg_result(to_integer(unsigned(current_input) + unsigned(one)))(1) and reg_result(to_integer(unsigned(current_input) + unsigned(one) ))(0) and not(reg_weight(1)(1))  and reg_weight(1)(0));
					   
						temp31 := (not(reg_result(to_integer(unsigned(current_input) + unsigned(two)))(1)) and reg_result(to_integer(unsigned(current_input) + unsigned(two)))(0) and reg_weight(2)(0) and reg_weight(2)(1));
					   temp32 := (reg_result(to_integer(unsigned(current_input) + unsigned(two)))(1) and reg_result(to_integer(unsigned(current_input) + unsigned(two)))(0) and not(reg_weight(2)(1))  and reg_weight(2)(0));
					   
						temp41 := (not(reg_result(to_integer(unsigned(current_input) + unsigned(three)))(1)) and reg_result(to_integer(unsigned(current_input) + unsigned(three)))(0) and reg_weight(3)(0) and reg_weight(3)(1));
					   temp42 := (reg_result(to_integer(unsigned(current_input) + unsigned(three)))(1) and reg_result(to_integer(unsigned(current_input) + unsigned(three)))(0) and not(reg_weight(3)(1))  and reg_weight(3)(0));
					   
						temp51 := (not(reg_result(to_integer(unsigned(current_input) + unsigned(four)))(1)) and reg_result(to_integer(unsigned(current_input) + unsigned(four)))(0) and reg_weight(4)(0) and reg_weight(4)(1));
					   temp52 := (reg_result(to_integer(unsigned(current_input) + unsigned(four)))(1) and reg_result(to_integer(unsigned(current_input) + unsigned(four)))(0) and not(reg_weight(4)(1))  and reg_weight(4)(0));
					   
						temp61 := (not(reg_result(to_integer(unsigned(current_input) + unsigned(five)))(1)) and reg_result(to_integer(unsigned(current_input) + unsigned(five)))(0) and reg_weight(5)(0) and reg_weight(5)(1));
					   temp62 := (reg_result(to_integer(unsigned(current_input) + unsigned(five)))(1) and reg_result(to_integer(unsigned(current_input) + unsigned(five)))(0) and not(reg_weight(5)(1))  and reg_weight(5)(0));
					   
						temp71 := (not(reg_result(to_integer(unsigned(current_input) + unsigned(six)))(1)) and reg_result(to_integer(unsigned(current_input) + unsigned(six)))(0) and reg_weight(6)(0) and reg_weight(6)(1));
					   temp72 := (reg_result(to_integer(unsigned(current_input) + unsigned(six)))(1) and reg_result(to_integer(unsigned(current_input) + unsigned(six)))(0) and not(reg_weight(6)(1))  and reg_weight(6)(0));
					   
						temp81 := (not(reg_result(to_integer(unsigned(current_input) + unsigned(seven)))(1)) and reg_result(to_integer(unsigned(current_input) + unsigned(seven)))(0) and reg_weight(7)(0) and reg_weight(7)(1));
					   temp82 := (reg_result(to_integer(unsigned(current_input) + unsigned(seven)))(1) and reg_result(to_integer(unsigned(current_input) + unsigned(seven)))(0) and not(reg_weight(7)(1))  and reg_weight(7)(0));	
						
                  kmap_res1(1) := temp11 or temp12;
						kmap_res2(1) := temp21 or temp22;	
	               kmap_res3(1) := temp31 or temp32;
	               kmap_res4(1) := temp41 or temp42;
	               kmap_res5(1) := temp51 or temp52;
	               kmap_res6(1) := temp61 or temp62;
	               kmap_res7(1) := temp71 or temp72;
	               kmap_res8(1) := temp81 or temp82;					
												
                  acc <= std_logic_vector(signed(acc)  + signed(kmap_res1) + signed(kmap_res2) + signed(kmap_res3) + signed(kmap_res4) + signed(kmap_res5) + signed(kmap_res6) + signed(kmap_res7) + signed(kmap_res8));	
						
						
					end if;
			stats<="10001";
	      when UPDATE_CUR_INP =>
						current_state <= N2_CHECK_INPUTS;	
						current_input <= std_logic_vector(unsigned (current_input) + unsigned(eight));
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');					
					
			when COMPARISON =>		
					if (signed(acc) > signed(p_threshhold)) then 
						current_state <= UPDATE_CUR_NEUR;
						
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');
						
					reg_result2(to_integer(unsigned(current_neuron))) <= "01";							
						
					elsif (signed(acc) < signed(n_threshhold)) then
						current_state <= UPDATE_CUR_NEUR;
						
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');
                  reg_result2(to_integer(unsigned(current_neuron))) <= "11";
						
					else
						current_state <= UPDATE_CUR_NEUR;
						
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');
						
                  reg_result2(to_integer(unsigned(current_neuron))) <= "00";						
					end if;	
			stats<="10010";		

         when UPDATE_CUR_NEUR =>
			        current_state <= N1_CHECK_NEURONS;
					  current_neuron <= std_logic_vector(unsigned (current_neuron) + unsigned(one));
						---master read signals
						av_address <= (others => '0'); 
				      av_byteenable <= (others => '0'); 
				      av_read  <= '0'; 
                  ---read flipfloop
						fifo_in_read_req <= '0'; 
				      fifo_in_write_req <='0';  
				      fifo_in_input <= (others => '0');
                  ---master write signals
				      av_write  <= '0'; 
				      av_writedata <= (others => '0');
				      ---master flip flop
					   fifo_mr_read_req <= '0';
                  fifo_mr_write_req <='0';
                  fifo_mr_input<=(others => '0');
						
         when PUSH_WAIT_RES => 
					current_state <= PUSH_RES;
					c_res_p <= std_logic_vector(unsigned(c_res_p) + unsigned(four));
					
					---master read signals
					av_address <= (others => '0'); 
					av_byteenable <= (others => '0'); 
					av_read  <= '0'; 
					---read flipfloop
					fifo_in_read_req <= '0';
					fifo_in_write_req <='0';  
					fifo_in_input <= (others => '0');
					---master write signals
					av_write  <= '0'; 
					av_writedata <= (others => '0');
					---master flip flop
					fifo_mr_read_req <= '0';
					fifo_mr_write_req <='0';
					fifo_mr_input<=(others => '0');					
               stats<="10011";	
					
			when  PUSH_RES=>		
					if (c_res_p < n_neurons) then 
						current_state <= PUSH_WAIT_RES;
						
					fifo_mr_input <= std_logic_vector(  (resize(signed (reg_result2(to_integer(unsigned(c_res_p) + unsigned(three)))),32)) & resize(signed (reg_result2(to_integer(unsigned(c_res_p) + unsigned(two)))),32) & resize(signed (reg_result2(to_integer(unsigned(c_res_p) + unsigned(one)))),32) & resize(signed (reg_result2(to_integer(unsigned(c_res_p)))),32) ) ;
					---master read signals
					av_address <= (others => '0'); 
					av_byteenable <= (others => '0'); 
					av_read  <= '0'; 
					---read flipfloop
					fifo_in_read_req <= '0';
					fifo_in_write_req <='0';  
					fifo_in_input <= (others => '0');
					---master write signals
					av_write  <= '0'; 
					av_writedata <= (others => '0');
					---master flip flop
					fifo_mr_read_req <= '0';
					fifo_mr_write_req <='1';
					
					
					else
						
					current_state <=WRITE_RES;
					c_res_w <= "00000000000";
					
					---master read signals
					av_address <= (others => '0'); 
					av_byteenable <= (others => '0'); 
					av_read  <= '0'; 
					---read flipfloop
					fifo_in_read_req <= '0';
					fifo_in_write_req <='0';  
					fifo_in_input <= (others => '0');
					---master write signals
					av_write  <= '0'; 
					av_writedata <= (others => '0');
					---master flip flop
					fifo_mr_read_req <= '0';
					fifo_mr_write_req <='0';
					fifo_mr_input<=(others => '0');
						
					end if;
					stats<="10100";	
		
         when  WRITE_RES=>		
					if (c_res_w < n_neurons) then 
						current_state <= IDLE_RES;
					
					---master read signals
					av_address <= std_logic_vector(unsigned(reg_av_address_value) + unsigned(unsigned(c_res_w) & unsigned(db_zero)));
					av_byteenable <= (others => '1'); 
					av_read  <= '0'; 
					---read flipfloop
					fifo_in_read_req <= '0';
					fifo_in_write_req <='0';  
					fifo_in_input <= (others => '0');
					---master write signals
					av_write  <= '1'; 
					av_writedata <= fifo_mr_output;
					---master flip flop
					fifo_mr_read_req <= '1';
					fifo_mr_write_req <='0';
					fifo_mr_input<= (others => '0'); 	
				
					else
					current_state <=EXITING;
					
					---master read signals
					av_address <= (others => '0'); 
					av_byteenable <= (others => '0'); 
					av_read  <= '0'; 
					---read flipfloop
					fifo_in_read_req <= '0';
					fifo_in_write_req <='0';  
					fifo_in_input <= (others => '0');
					---master write signals
					av_write  <= '0'; 
					av_writedata <= (others => '0');
					---master flip flop
					fifo_mr_read_req <= '0';
					fifo_mr_write_req <='0';
					fifo_mr_input<=(others => '0');					
					end if;
					stats<="10101";	

		   when  IDLE_RES=>		
					if (av_waitrequest = '0') then 
					current_state <= WRITE_RES;
					c_res_w <= std_logic_vector(unsigned(c_res_w) + unsigned(four));
					
					---master read signals
					av_address <= (others => '0'); 
					av_byteenable <= (others => '0'); 
					av_read  <= '0'; 
					---read flipfloop
					fifo_in_read_req <= '0';
					fifo_in_write_req <='0';  
					fifo_in_input <= (others => '0');
					---master write signals
					av_write  <= '0'; 
					av_writedata <= (others => '0');
					---master flip flop
					fifo_mr_read_req <= '0';
					fifo_mr_write_req <='0';
					fifo_mr_input<=(others => '0');					
					
					else
					current_state <=IDLE_RES;
						

					---master flip flop
					fifo_mr_read_req <= '0';

						
					end if;
					stats<="10110";	
					
			when EXITING=> 
			   if(start(0)= '1') then
			      current_state <= EXITING;
						
					---master read signals
					av_address <= (others => '0'); 
					av_byteenable <= (others => '0'); 
					av_read  <= '0'; 
					---read flipfloop
					fifo_in_read_req <= '0';
					fifo_in_write_req <='0';  
					fifo_in_input <= (others => '0');
					---master write signals
					av_write  <= '0'; 
					av_writedata <= (others => '0');
					---master flip flop
					fifo_mr_read_req <= '0';
					fifo_mr_write_req <='0';
					fifo_mr_input<=(others => '0');
					
					done_main <='1';						
				
				else 		
					current_state <= INIT;
					
					---master read signals
					av_address <= (others => '0'); 
					av_byteenable <= (others => '0'); 
					av_read  <= '0'; 
					---read flipfloop
					fifo_in_read_req <= '0';
					fifo_in_write_req <='0';  
					fifo_in_input <= (others => '0');
					---master write signals
					av_write  <= '0'; 
					av_writedata <= (others => '0');
					---master flip flop
					fifo_mr_read_req <= '0';
					fifo_mr_write_req <='0';
					fifo_mr_input<=(others => '0');
					done_main <='0';						
				
				end if;
			stats<="10111";	
		end case;	
	end if;
end process;

done_wr<='0';
end Behavioral;
