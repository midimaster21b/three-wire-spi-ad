library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xpm;
use xpm.vcomponents.all;

entity three_wire_spi_cdc is
  generic (
    NUM_ADDR_BITS_G : integer := 5;
    NUM_DATA_BITS_G : integer := 32
    );
  port (
    axi_clk_p            : in  std_logic;
    spi_clk_p            : in  std_logic;

    -- AXI module interface
    axi_rst_in_p         : in  std_logic;
    axi_trig_in_p        : in  std_logic;
    axi_rw_in_p          : in  std_logic;
    axi_addr_in_p        : in  std_logic_vector(NUM_ADDR_BITS_G-1 downto 0);
    axi_write_data_in_p  : in  std_logic_vector(NUM_DATA_BITS_G-1 downto 0);

    axi_read_data_out_p  : out std_logic_vector(NUM_DATA_BITS_G-1 downto 0);
    axi_valid_out_p      : out std_logic;


    -- SPI module interface
    spi_rst_out_p        : out std_logic;
    spi_trig_out_p       : out std_logic;
    spi_rw_out_p         : out std_logic;
    spi_addr_out_p       : out std_logic_vector(NUM_ADDR_BITS_G-1 downto 0);
    spi_write_data_out_p : out std_logic_vector(NUM_DATA_BITS_G-1 downto 0);

    spi_read_data_in_p   : in  std_logic_vector(NUM_DATA_BITS_G-1 downto 0);
    spi_valid_in_p       : in  std_logic
    );
end three_wire_spi_cdc;

architecture rtl of three_wire_spi_cdc is

begin

  -- axi_addr_in_p
  u_addr_cdc : xpm_cdc_array_single
    generic map (
      DEST_SYNC_FF   => 10,
      INIT_SYNC_FF   => 0,
      SIM_ASSERT_CHK => 0,
      SRC_INPUT_REG  => 1,
      WIDTH          => NUM_ADDR_BITS_G
      )
    port map (
      src_clk  => axi_clk_p,
      src_in   => axi_addr_in_p,
      dest_clk => spi_clk_p,
      dest_out => spi_addr_out_p
      );

  -- axi_data_in_p
  u_write_data_cdc : xpm_cdc_array_single
    generic map (
      DEST_SYNC_FF   => 10,
      INIT_SYNC_FF   => 0,
      SIM_ASSERT_CHK => 0,
      SRC_INPUT_REG  => 1,
      WIDTH          => NUM_DATA_BITS_G
      )
    port map (
      src_clk  => axi_clk_p,
      src_in   => axi_write_data_in_p,
      dest_clk => spi_clk_p,
      dest_out => spi_write_data_out_p
      );

  -- axi_data_out_p
  u_read_data_cdc : xpm_cdc_array_single
    generic map (
      DEST_SYNC_FF   => 4,
      INIT_SYNC_FF   => 0,
      SIM_ASSERT_CHK => 0,
      SRC_INPUT_REG  => 1,
      WIDTH          => NUM_DATA_BITS_G
      )
    port map (
      src_clk  => spi_clk_p,
      src_in   => spi_read_data_in_p,
      dest_clk => axi_clk_p,
      dest_out => axi_read_data_out_p
      );


  -- axi_rst_in_p
  u_rst_cdc : xpm_cdc_single
    generic map (
      DEST_SYNC_FF   => 10,
      INIT_SYNC_FF   => 0,
      SIM_ASSERT_CHK => 0,
      SRC_INPUT_REG  => 1
      )
    port map (
      src_clk        => axi_clk_p, 
      src_in         => axi_rst_in_p,
      dest_clk       => spi_clk_p,
      dest_out       => spi_rst_out_p
      );

  -- axi_rw_in_p
  u_rw_cdc : xpm_cdc_single
    generic map (
      DEST_SYNC_FF   => 10,
      INIT_SYNC_FF   => 0,
      SIM_ASSERT_CHK => 0,
      SRC_INPUT_REG  => 1
      )
    port map (
      src_clk        => axi_clk_p,
      src_in         => axi_rw_in_p,
      dest_clk       => spi_clk_p,
      dest_out       => spi_rw_out_p
      );

  -- axi_valid_out_p
  u_valid_cdc : xpm_cdc_single
    generic map (
      DEST_SYNC_FF   => 4,
      INIT_SYNC_FF   => 0,
      SIM_ASSERT_CHK => 0,
      SRC_INPUT_REG  => 1
      )
    port map (
      src_clk        => spi_clk_p,
      src_in         => spi_valid_in_p,
      dest_clk       => axi_clk_p,
      dest_out       => axi_valid_out_p
      );


  -- axi_trig_in_p
  u_trig_pulse : xpm_cdc_pulse
    generic map (
      DEST_SYNC_FF   => 10,
      INIT_SYNC_FF   => 0,
      REG_OUTPUT     => 0,
      RST_USED       => 0,
      SIM_ASSERT_CHK => 0
      )
    port map (
      src_clk    => axi_clk_p,
      src_rst    => '0', -- axi_rst_in_p
      src_pulse  => axi_trig_in_p,
      dest_clk   => spi_clk_p,
      dest_rst   => '0', -- spi_rst_out_p
      dest_pulse => spi_trig_out_p
      );

end rtl;
