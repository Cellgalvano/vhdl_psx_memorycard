
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- JB0 = DATA (MISO)
-- JB1 = ACK
-- JC0 = CLK (SCLK)
-- JC1 = CMD (MOSI)
-- JC2 = ATT (NSS)

entity top is
  Port (
    clk: in std_logic;
    sw: in std_logic_vector(15 downto 0);
    led: out std_logic_vector(15 downto 0);
    btnC: in std_logic;
    JB: out std_logic_vector(7 downto 0);
    JC: in std_logic_vector(7 downto 0);
    RsRx: in std_logic;
    RsTx: out std_logic
  );
end top;

architecture Behavioral of top is
    signal rst: std_logic;
    signal int_rst: std_logic := '0';
    signal data_valid: std_logic;
    signal data_fromSPItoFSM: std_logic_vector(7 downto 0);
    signal data_fromFSMtoSPI: std_logic_vector(7 downto 0);
    signal csn_d: std_logic;
    signal cardselected: std_logic;
    signal ack_i: std_logic;
    signal data_i: std_logic;
begin
    
    rst <= btnC or int_rst;
    led(7 downto 0) <= data_fromSPItoFSM;
    led(15 downto 8) <= data_fromFSMtoSPI;

    ss1: entity work.spi_slave port map(
        clk => clk,
		rst => rst,
		sck => JC(0),
		mosi => JC(1),
		miso => data_i,
		csn => JC(2),
		data_out => data_fromSPItoFSM,
		data_in => data_fromFSMtoSPI,
		valid => data_valid
    );
    
    fsm: entity work.memcard_fsm port map(
        clk => clk,
		rst => rst,
		valid => data_valid,
		data_in => data_fromSPItoFSM,
		data_out => data_fromFSMtoSPI,
		ack => ack_i,
		selected => cardselected
    );
    
    process (clk) begin
        if(cardselected = '1') then
            JB(0) <= data_i;
            JB(1) <= ack_i;
        else
            JB(0) <= 'Z';
            JB(1) <= 'Z';
        end if;  
    end process;
    
    process (clk) begin
        if(rising_edge(clk)) then
            if(JC(2) = '1' and csn_d = '0') then
                int_rst <= '1';
            else
                int_rst <= '0';
            end if;
            csn_d <= JC(2);
        end if;
    end process;

end Behavioral;
