library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
  u_addr_cdc : entity work.cdc_array(rtl)
    generic map (
      NUM_FF_G   => 10,
      NUM_BITS_G => NUM_ADDR_BITS_G
      )
    port map (
      src_clk_in    => axi_clk_p,
      dest_clk_in   => spi_clk_p,

      src_data_in   => axi_addr_in_p,
      dest_data_out => spi_addr_out_p
      );




  -- axi_data_in_p
  u_write_data_cdc : entity work.cdc_array(rtl)
    generic map (
      NUM_FF_G   => 10,
      NUM_BITS_G => NUM_DATA_BITS_G
      )
    port map (
      src_clk_in    => axi_clk_p,
      dest_clk_in   => spi_clk_p,

      src_data_in   => axi_write_data_in_p,
      dest_data_out => spi_write_data_out_p
      );

  -- axi_data_out_p
  u_read_data_cdc : entity work.cdc_array(rtl)
    generic map (
      NUM_FF_G   => 10,
      NUM_BITS_G => NUM_DATA_BITS_G
      )
    port map (
      src_clk_in    => spi_clk_p,
      dest_clk_in   => axi_clk_p,

      src_data_in   => spi_read_data_in_p,
      dest_data_out => axi_read_data_out_p
      );

  -- axi_rst_in_p
  u_rst_cdc: entity work.cdc_bit(rtl)
    generic map (
      NUM_FF_G => 10
      )
    port map (
      src_clk_in    => axi_clk_p,
      dest_clk_in   => spi_clk_p,

      src_data_in   => axi_rst_in_p,
      dest_data_out => spi_rst_out_p
      );

  -- axi_rw_in_p
  u_rw_cdc: entity work.cdc_bit(rtl)
    generic map (
      NUM_FF_G => 10
      )
    port map (
      src_clk_in    => axi_clk_p,
      dest_clk_in   => spi_clk_p,

      src_data_in   => axi_rw_in_p,
      dest_data_out => spi_rw_out_p
      );

  -- axi_valid_out_p
  u_valid_cdc: entity work.cdc_bit(rtl)
    generic map (
      NUM_FF_G => 4
      )
    port map (
      src_clk_in    => spi_clk_p,
      dest_clk_in   => axi_clk_p,

      src_data_in   => spi_valid_in_p,
      dest_data_out => axi_valid_out_p
      );


  -- axi_trig_in_p
  u_trig_pulse_cdc: entity work.cdc_pulse(rtl)
    port map (
    src_clk_in    => axi_clk_p,
    dest_clk_in   => spi_clk_p,

    src_data_in   => axi_trig_in_p,
    dest_data_out => spi_trig_out_p
    );


end rtl;
