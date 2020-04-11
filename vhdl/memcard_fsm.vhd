
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memcard_fsm is
    Port (
        clk: in std_logic;
		rst: in std_logic;
		valid: in std_logic;
		data_in: in std_logic_vector(7 downto 0);
		data_out: out std_logic_vector(7 downto 0);
		ack: out std_logic;
		selected: out std_logic
    );
end memcard_fsm;

architecture Behavioral of memcard_fsm is
    signal ack_counter: unsigned(10 downto 0) := "00000000000";
    
    type CARD_STATE is (CARD_IDLE, CARD_GETCMD, CARD_SENDID1, CARD_SENDID2, CARD_GETADDR_MSB, CARD_GETADDR_LSB, 
    CARD_SENDCMDACK1, CARD_SENDCMDACK2, CARD_RETURN_MSB, CARD_RETURN_LSB, CARD_SENDDATA, CARD_SENDCHECKSUM, CARD_SENDENDBYTE, CARD_GETDATA);
	signal state: CARD_STATE := CARD_IDLE;
	
	type RAM is array(0 to 131071) of std_logic_vector(7 downto 0); -- 128 KB = 1024 Sectors * 128 Bytes
    signal mem: RAM;
    signal checksum: std_logic_vector(7 downto 0) := "00000000";
    signal flagbyte: std_logic_vector(7 downto 0) := "00001000";
    signal memaddr: std_logic_vector(15 downto 0) := (others => '0');
    signal valid_d: std_logic;
    signal bytecounter: unsigned(6 downto 0) := "0000000";
    signal activecmd: std_logic_vector(7 downto 0) := "00000000";
    signal memcomb: std_logic_vector(16 downto 0) := (others => '0');
    signal membuf: std_logic_vector(7 downto 0) := "00000000";
begin

    memcomb <= memaddr(9 downto 0) & std_logic_vector(bytecounter);

    process (clk) begin
        if(rising_edge(clk)) then
            if(rst = '1') then
                ack_counter <= "00000000000";
            else
                if(valid = '1') then
                    ack_counter <= "11111111111";
                else
                    if(ack_counter > 0) then
                        ack_counter <= ack_counter - 1;
                        ack <= '0';
                        if(ack_counter > 300) then ack <= '1'; end if;
                    else
                        ack <= '1';
                    end if;
                end if;    
            end if;
        end if;
    end process;

    process (clk) begin
        if(rising_edge(clk)) then 
            if rst = '1' then
                state <= CARD_IDLE;
                data_out <= "00000000";
            else
                selected <= '1';
                case(state) is
                    when CARD_IDLE => if(valid = '1' and valid_d = '0') then
                        if(data_in = "10000001") then
                            -- 0x81 MC SELECTED
                            data_out <= flagbyte;
                            bytecounter <= "0000000";
                            CHECKSUM <= "00000000";
                            activecmd <= "00000000";
                            selected <= '0';
                            state <= CARD_GETCMD;
                        end if;
                    end if;
                    when CARD_GETCMD => if(valid = '1' and valid_d = '0') then
                        activecmd <= data_in;
                        if(data_in = "01010010" or data_in = "01010111") then
                            -- 0x52 READ
                            -- 0x57 WRITE
                            data_out <= "01011010"; -- 0x5A ID1
                            state <= CARD_SENDID1;
                        end if;
                    end if;
                    when CARD_SENDID1 => if(valid = '1' and valid_d = '0') then
    
                            data_out <= "01011101"; -- 0x5D ID2
                            state <= CARD_SENDID2;
                        
                    end if;
                    when CARD_SENDID2 => if(valid = '1' and valid_d = '0') then
    
                            data_out <= "00000000"; -- DUMMY
                            state <= CARD_GETADDR_MSB;
                        
                    end if;
                    when CARD_GETADDR_MSB => if(valid = '1' and valid_d = '0') then
                            
                            memaddr(15 downto 8) <= data_in; -- MSB
    
                            data_out <= memaddr(15 downto 8); -- PRE MSB
                            state <= CARD_GETADDR_LSB;
                        
                    end if;
                    when CARD_GETADDR_LSB => if(valid = '1' and valid_d = '0') then
                            
                            memaddr(7 downto 0) <= data_in; -- LSB
                            if(activecmd = "01010010") then
                                -- READ
                                data_out <= "01011100"; -- 0x5C ACK1
                                state <= CARD_SENDCMDACK1;
                            end if;
                            if(activecmd = "01010111") then
                                -- WRITE
                                data_out <= memaddr(7 downto 0); -- PRE LSB
                                state <= CARD_GETDATA;
                                flagbyte(2) <= '1';
                            end if;
                        
                    end if;
                    when CARD_GETDATA => if(valid = '1' and valid_d = '0') then
                            
                            data_out <= data_in;
                            mem(to_integer(unsigned(memcomb))) <= data_in;
                            if(bytecounter = "1111111") then
                                data_out <= "01011100"; -- 0x5C ACK1
                                state <= CARD_SENDCMDACK1;
                            else
                                bytecounter <= bytecounter + 1;
                            end if;
                        
                    end if;
                    when CARD_SENDCMDACK1 => if(valid = '1' and valid_d = '0') then
    
                            data_out <= "01011101"; -- 0x5D ACK1
                            if(activecmd = "01010010") then
                                -- READ
                                state <= CARD_SENDCMDACK2;
                            end if;
                            if(activecmd = "01010111") then
                                -- WRITE
                                state <= CARD_SENDENDBYTE;
                            end if;
                        
                    end if;
                    when CARD_SENDCMDACK2 => if(valid = '1' and valid_d = '0') then
    
                            data_out <= memaddr(15 downto 8); -- MSB
                            state <= CARD_RETURN_MSB;
                        
                    end if;
                    when CARD_RETURN_MSB => if(valid = '1' and valid_d = '0') then
    
                            data_out <= memaddr(7 downto 0); -- LSB
                            state <= CARD_RETURN_LSB;
                        
                    end if;
                    when CARD_RETURN_LSB => 
                        membuf <= mem(to_integer(unsigned(memcomb)));
                        if(valid = '1' and valid_d = '0') then
    
                            data_out <= membuf; -- FIRST BYTE
                            CHECKSUM <= CHECKSUM xor membuf;
                            bytecounter <= bytecounter + 1;
                            state <= CARD_SENDDATA;
                        
                        end if;
                    when CARD_SENDDATA => 
                        membuf <= mem(to_integer(unsigned(memcomb)));
                        if(valid = '1' and valid_d = '0') then
                            --data_out <= '0' & std_logic_vector(bytecounter); -- DATA BYTE
                            data_out <= membuf;
                            CHECKSUM <= CHECKSUM xor membuf;
                            if(bytecounter = "1111111") then
                                --data_out <= CHECKSUM xor memaddr(15 downto 8) xor memaddr(7 downto 0);
                                state <= CARD_SENDCHECKSUM;
                            else
                                bytecounter <= bytecounter + 1;
                            end if;
                        end if;
                    when CARD_SENDCHECKSUM => if(valid = '1' and valid_d = '0') then
    
                            data_out <= memaddr(15 downto 8) xor memaddr(7 downto 0) xor CHECKSUM;
                            state <= CARD_SENDENDBYTE;
                        
                    end if;
                    when CARD_SENDENDBYTE => if(valid = '1' and valid_d = '0') then
    
                            data_out <= "01000111"; -- END BYTE
                            state <= CARD_IDLE;
                        
                    end if;
    
                end case;
                valid_d <= valid;
            end if;
        end if;
    end process;

end Behavioral;
