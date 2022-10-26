library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

entity three_wire_spi_top is
  generic (
    NUM_ADDR_BITS_G : integer := 13;
    NUM_DATA_BITS_G : integer := 8
    );
  port (
    -- Control lines
    spi_clk_in_p         : in    std_logic;
    spi_rst_in_p         : in    std_logic;

    -- SPI interface
    sclk_p               : out   std_logic;
    sdio_p               : inout std_logic;
    csn_p                : out   std_logic;

    -- Message lines
    spi_trig_in_p        : in    std_logic;
    spi_addr_in_p        : in    std_logic_vector(NUM_ADDR_BITS_G-1 downto 0);
    spi_rw_in_p          : in    std_logic;
    spi_data_in_p        : in    std_logic_vector(NUM_DATA_BITS_G-1 downto 0);

    spi_data_out_p       : out   std_logic_vector(NUM_DATA_BITS_G-1 downto 0);
    spi_data_valid_out_p : out   std_logic
    );
end three_wire_spi_top;


architecture rtl of three_wire_spi_top is
  -----------------------------------------------------------------------------
  -- Constants and Types
  -----------------------------------------------------------------------------
  constant NUM_HEADER_BITS_C : integer := 16;
  constant NUM_DATA_BITS_C   : integer := NUM_DATA_BITS_G;
  constant RW_READ_C         : std_logic := '0';
  constant RW_WRITE_C        : std_logic := '0';

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- SPI
  signal sclk_en_s           : std_logic;
  signal sdio_in_s           : std_logic;
  signal sdio_out_s          : std_logic;
  signal sdio_in_a_s         : std_logic := '0';
  signal sdio_in_b_s         : std_logic := '0';
  signal spi_clk_in_ns       : std_logic;
  signal sdio_high_z_s       : std_logic;

begin

  spi_clk_in_ns <= not spi_clk_in_p;

  sdio_p    <= 'Z' when sdio_high_z_s = '1' else sdio_out_s;
  sdio_in_s <= sdio_p;


  -----------------------------------------------------------------------------
  -- Components
  -----------------------------------------------------------------------------
  -- Clock gating
  u_spi_clk_gate : BUFGCE
    generic map (
      CE_TYPE        => "SYNC",           -- ASYNC, HARDSYNC, SYNC
      IS_CE_INVERTED => '0',              -- Programmable inversion on CE
      IS_I_INVERTED  => '0',              -- Programmable inversion on I
      SIM_DEVICE     => "ULTRASCALE_PLUS" -- ULTRASCALE, ULTRASCALE_PLUS
      )
    port map (
      O  => sclk_p,      -- 1-bit output: Buffer
      CE => sclk_en_s,   -- 1-bit input: Buffer enable
      I  => spi_clk_in_p -- 1-bit input: Buffer
      );


  -- Get falling edge data
  u_spi_data : IDDRE1
    generic map (
      DDR_CLK_EDGE   => "OPPOSITE_EDGE", -- IDDRE1 mode (OPPOSITE_EDGE, SAME_EDGE, SAME_EDGE_PIPELINED)
      IS_CB_INVERTED => '0',             -- Optional inversion for CB
      IS_C_INVERTED  => '0'              -- Optional inversion for C
      )
    port map (
      Q1 => sdio_in_a_s,   -- 1-bit output: Registered parallel output 1
      Q2 => sdio_in_b_s,   -- 1-bit output: Registered parallel output 2
      C  => spi_clk_in_p,  -- 1-bit input: High-speed clock
      CB => spi_clk_in_ns, -- 1-bit input: Inversion of High-speed clock C
      D  => sdio_in_s,     -- 1-bit input: Serial Data Input
      R  => spi_rst_in_p   -- 1-bit input: Active-High Async Reset
      );


  u_three_wire_spi: entity work.three_wire_spi(rtl)
    generic map (
      NUM_ADDR_BITS_G => NUM_ADDR_BITS_G,
      NUM_DATA_BITS_G => NUM_DATA_BITS_G
    )
    port map (
      -- Control lines
      spi_clk_in_p         => spi_clk_in_p,
      spi_rst_in_p         => spi_rst_in_p,

      -- SPI interface
      sclk_en_p            => sclk_en_s,
      sdio_in_p            => sdio_in_b_s, -- sdio_in_s
      sdio_out_p           => sdio_out_s,
      sdio_high_z_p        => sdio_high_z_s,
      csn_p                => csn_p,

      -- Message lines
      spi_trig_in_p        => spi_trig_in_p,
      spi_addr_in_p        => spi_addr_in_p,
      spi_rw_in_p          => spi_rw_in_p,
      spi_data_in_p        => spi_data_in_p,

      spi_data_out_p       => spi_data_out_p,
      spi_data_valid_out_p => spi_data_valid_out_p
      );

end rtl;