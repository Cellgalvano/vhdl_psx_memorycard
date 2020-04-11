library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity spi_slave is
	Port(
		clk: in std_logic;
		rst: in std_logic;
		sck: in std_logic;
		mosi: in std_logic;
		miso: out std_logic;
		csn: in std_logic;
		data_out: out std_logic_vector(7 downto 0);
		data_in: in std_logic_vector(7 downto 0);
		valid: out std_logic
	);
end spi_slave;

architecture Behavioral of spi_slave is
	type SPI_STATE is (SPI_IDLE, SPI_DATA, SPI_STOP);
	signal state: SPI_STATE := SPI_IDLE;
	signal data_rx: std_logic_vector(7 downto 0) := "00000000";
	signal data_tx: std_logic_vector(7 downto 0) := "00000000";
	signal bit_cnt: natural range 0 to 7 := 0;
	signal sck_d: std_logic;
	signal sck_i: std_logic;
	signal csn_d: std_logic; 
	signal csn_i: std_logic; 
begin
	
	process(clk) begin
		if(rising_edge(clk)) then
			sck_i <= sck;
			csn_i <= csn;
			if(rst = '1') then
				state <= SPI_IDLE;
			else
				valid <= '0';
				case(state) is
					when SPI_IDLE => 
						bit_cnt <= 0;
						data_rx <= "00000000";
						if(csn_i = '0' and csn_d = '1') then
							state <= SPI_DATA;
					        data_tx <= data_in;
						end if;
					when SPI_DATA => 
					    data_tx <= data_in;
					    if(sck_i = '0' and sck_d = '1') then
                            data_rx <= mosi & data_rx(7 downto 1); -- LSBFIRST
                            --data <= data(6 downto 0) & mosi; -- MSBFIRST
                            miso <= data_tx(bit_cnt);
                            bit_cnt <= bit_cnt + 1;
                            if(bit_cnt = 7) then
                                state <= SPI_STOP;
                            end if;
                            if(csn_i = '1' and csn_d = '0') then
                                state <= SPI_IDLE;
                            end if;
					    end if;
					when SPI_STOP => 
                        data_out <= data_rx;
                        valid <= '1';
                        bit_cnt <= 0;
                        state <= SPI_DATA;
				end case;
				sck_d <= sck_i;
				csn_d <= csn_i;

			end if;
		end if;
	end process;

end Behavioral;
