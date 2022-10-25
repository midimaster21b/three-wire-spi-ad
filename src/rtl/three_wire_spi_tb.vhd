library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;


entity three_wire_spi_tb is
end three_wire_spi_tb;

architecture sim of three_wire_spi_tb is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant NUM_ADDR_BITS_C : integer := 13;
  constant NUM_DATA_BITS_C : integer := 8;
  constant CLK_25_PERIOD_C : time    := 40 ns; -- 25 MHz

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Control
  signal clk_s : std_logic := '0';
  signal rst_s : std_logic := '1';

  -- SPI
  signal spi_sclk_s   : std_logic := '0';
  signal spi_sdio_s   : std_logic;
  signal spi_csn_s    : std_logic;
  signal spi_high_z_s : std_logic;

  -- Message
  signal spi_trig_s : std_logic := '0';
  signal spi_addr_s : std_logic_vector(NUM_ADDR_BITS_C-1 downto 0) := "1010110010011";
  signal spi_data_s : std_logic_vector(NUM_DATA_BITS_C-1 downto 0) := x"AB";
  -- signal spi_rw_s   : std_logic := '1';
  signal spi_rw_s   : std_logic := '0';

  signal spi_read_data_s  : std_logic_vector(NUM_DATA_BITS_C-1 downto 0);
  signal spi_data_valid_s : std_logic;


begin

  rst_s         <= '0'       after 100 ns;
  clk_s         <= not clk_s after CLK_25_PERIOD_C/2;

  process
  begin
    wait for 400 ns;
    spi_trig_s    <= '1';
    wait for CLK_25_PERIOD_C;
    spi_trig_s    <= '0';
    wait;
  end process;


  u_dut: entity work.three_wire_spi_top(rtl)
    generic map (
      NUM_ADDR_BITS_G => NUM_ADDR_BITS_C,
      NUM_DATA_BITS_G => NUM_DATA_BITS_C
      )
    port map (
      -- Control lines
      spi_clk_in_p         => clk_s,
      spi_rst_in_p         => rst_s,

      -- SPI interface
      sclk_en_p            => spi_sclk_s,
      sdio_in_p            => spi_sdio_s,
      sdio_out_p           => spi_sdio_s,
      sdio_high_z_p        => spi_high_z_s,
      csn_p                => spi_csn_s,

      -- Message lines
      spi_trig_in_p        => spi_trig_s,
      spi_addr_in_p        => spi_addr_s,
      spi_rw_in_p          => spi_rw_s,
      spi_data_in_p        => spi_data_s,

      spi_data_out_p       => spi_read_data_s,
      spi_data_valid_out_p => spi_data_valid_s
      );
end sim;
