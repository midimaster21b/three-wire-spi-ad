library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

entity three_wire_spi is
  generic (
    NUM_ADDR_BITS_G : integer := 13;
    NUM_DATA_BITS_G : integer := 8
    );
  port (
    -- Control lines
    spi_clk_in_p         : in    std_logic;
    spi_rst_in_p         : in    std_logic;

    -- SPI interface
    sclk_en_p            : out   std_logic;
    sdio_in_p            : in    std_logic;
    sdio_out_p           : out   std_logic;
    sdio_high_z_p        : out   std_logic;
    csn_p                : out   std_logic;

    -- Message lines
    spi_trig_in_p        : in    std_logic;
    spi_addr_in_p        : in    std_logic_vector(NUM_ADDR_BITS_G-1 downto 0);
    spi_rw_in_p          : in    std_logic;
    spi_data_write_in_p  : in    std_logic_vector(NUM_DATA_BITS_G-1 downto 0);

    spi_data_read_out_p  : out   std_logic_vector(NUM_DATA_BITS_G-1 downto 0);
    spi_data_valid_out_p : out   std_logic
    );
end three_wire_spi;


architecture rtl of three_wire_spi is
  -----------------------------------------------------------------------------
  -- Constants and Types
  -----------------------------------------------------------------------------
  constant NUM_HEADER_BITS_C : integer := 16;
  constant NUM_DATA_BITS_C   : integer := NUM_DATA_BITS_G;
  constant RW_READ_C         : std_logic := '0';
  constant RW_WRITE_C        : std_logic := '0';

  type SPI_STATE_C is (SPI_IDLE_STATE, SPI_INIT_STATE, SPI_HEADER_STATE, SPI_WRITE_STATE, SPI_READ_STATE, SPI_READ_OUT_STATE, SPI_END_STATE);

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- State machine
  signal curr_spi_state_r : SPI_STATE_C := SPI_IDLE_STATE;
  signal next_spi_state_s : SPI_STATE_C := SPI_IDLE_STATE;

  -- SPI
  signal sclk_r              : std_logic;
  signal sclk_en_r           : std_logic := '0';
  signal sdio_r              : std_logic := '0';
  signal sdio_high_z_r       : std_logic := '0';
  signal csn_r               : std_logic := '1';

  signal sdio_in_a_r         : std_logic := '0';
  signal sdio_in_b_r         : std_logic := '0';

  signal spi_clk_in_ns       : std_logic;

  -- Message
  signal spi_rw_r         : std_logic := RW_READ_C; -- 0: read, -- 1: write
  signal spi_addr_r       : std_logic_vector(NUM_ADDR_BITS_G-1 downto 0) := (others => '0');
  signal spi_read_data_r  : std_logic_vector(NUM_DATA_BITS_G-1 downto 0) := (others => '0');
  signal spi_data_write_r : std_logic_vector(NUM_DATA_BITS_G-1 downto 0) := (others => '0');

  signal spi_header_r     : std_logic_vector(15 downto 0) := (others => '0');
  signal spi_data_valid_r : std_logic := '0';

  -- Counters
  signal spi_header_counter_r : unsigned(4 downto 0) := (others => '0');
  signal data_counter_r       : unsigned(4 downto 0) := (others => '0');

begin

  -- SPI outputs
  sclk_en_p     <= sclk_en_r;
  sdio_out_p    <= sdio_r;
  sdio_high_z_p <= sdio_high_z_r;
  csn_p         <= csn_r;
  spi_clk_in_ns <= not spi_clk_in_p;

  -- Message output
  spi_data_valid_out_p <= spi_data_valid_r;
  spi_data_read_out_p  <= spi_read_data_r;

  --------------------------------------
  -- Advance to the next state
  --------------------------------------
  adv_state: process(spi_clk_in_p)
  begin
    if(rising_edge(spi_clk_in_p)) then
      if(spi_rst_in_p = '1') then
        curr_spi_state_r <= SPI_IDLE_STATE;

      else
        curr_spi_state_r <= next_spi_state_s;

      end if;
    end if;
  end process;


  --------------------------------------
  -- Calculate the next state
  --------------------------------------
  calc_state: process(curr_spi_state_r, spi_trig_in_p, spi_rw_r, spi_header_counter_r, data_counter_r)
  begin
    case curr_spi_state_r is
      when SPI_IDLE_STATE =>
        -- When triggered, go to the next state
        if(spi_trig_in_p = '1') then
          next_spi_state_s <= SPI_INIT_STATE;

        else
          next_spi_state_s <= SPI_IDLE_STATE;

        end if;


      when SPI_INIT_STATE =>
        next_spi_state_s <= SPI_HEADER_STATE;


      when SPI_HEADER_STATE =>
        if(spi_header_counter_r = NUM_HEADER_BITS_C-1) then
          if(spi_rw_r = RW_READ_C) then
            next_spi_state_s <= SPI_READ_STATE;

          else
            next_spi_state_s <= SPI_WRITE_STATE;

          end if;

        else
          next_spi_state_s <= SPI_HEADER_STATE;

        end if;


      when SPI_WRITE_STATE =>
        if(data_counter_r = NUM_DATA_BITS_C-1) then
          next_spi_state_s <= SPI_END_STATE;

        else
          next_spi_state_s <= SPI_WRITE_STATE;

        end if;


      when SPI_READ_STATE =>
        if(data_counter_r = NUM_DATA_BITS_C-1) then
          next_spi_state_s <= SPI_READ_OUT_STATE;

        else
          next_spi_state_s <= SPI_READ_STATE;

        end if;


      when SPI_READ_OUT_STATE =>
        next_spi_state_s <= SPI_END_STATE;


      when SPI_END_STATE =>
        next_spi_state_s <= SPI_IDLE_STATE;


      when others =>
        next_spi_state_s <= SPI_IDLE_STATE;

    end case;
  end process;


  --------------------------------------
  -- Counters
  --------------------------------------
  count_proc: process(spi_clk_in_p)
  begin
    if(rising_edge(spi_clk_in_p)) then
      if(spi_rst_in_p = '1') then
        spi_header_counter_r <= (others => '0');
        data_counter_r       <= (others => '0');

      else
        -----------------------
        -- Header counter
        -----------------------
        if(curr_spi_state_r = SPI_HEADER_STATE) then
          spi_header_counter_r <= spi_header_counter_r + 1;

        else
          spi_header_counter_r <= (others => '0');

        end if;

        -----------------------
        -- Data counter
        -----------------------
        if(curr_spi_state_r = SPI_READ_STATE or curr_spi_state_r = SPI_WRITE_STATE) then
          data_counter_r <= data_counter_r + 1;

        else
          data_counter_r <= (others => '0');

        end if;

      end if;
    end if;
  end process;


  --------------------------------------
  -- Register values
  --------------------------------------
  reg_proc: process(spi_clk_in_p)
  begin
    if(rising_edge(spi_clk_in_p)) then
      if(curr_spi_state_r = SPI_IDLE_STATE) then
        spi_rw_r       <= spi_rw_in_p;
        spi_addr_r     <= spi_addr_in_p;
        spi_data_write_r <= spi_data_write_in_p;

        spi_header_r   <= spi_rw_in_p & "00" & spi_addr_in_p;

      end if;
    end if;
  end process;


  --------------------------------------
  -- Handle output lines
  --------------------------------------
  spi_proc: process(spi_clk_in_p)
  begin
    if(rising_edge(spi_clk_in_p)) then
      case curr_spi_state_r is
        when SPI_IDLE_STATE =>
          sclk_en_r     <= '0';
          sdio_r        <= '0';
          sdio_high_z_r <= '0';
          csn_r         <= '1';

        when SPI_INIT_STATE =>
          sclk_en_r     <= '1'; -- Enable clock
          sdio_r        <= '0';
          sdio_high_z_r <= '0';
          csn_r         <= '0'; -- Drop CSN

        when SPI_HEADER_STATE =>
          sclk_en_r     <= '1'; -- Enable clock
          sdio_r        <= spi_header_r(15-to_integer(spi_header_counter_r)); -- Header data
          sdio_high_z_r <= '0';
          csn_r         <= '0'; -- Drop CSN

        when SPI_WRITE_STATE =>
          sclk_en_r     <= '1'; -- Enable clock
          sdio_r        <= spi_data_write_r(7-to_integer(data_counter_r));
          sdio_high_z_r <= '0';
          csn_r         <= '0'; -- Drop CSN

        when SPI_READ_STATE =>
          -- if(to_integer(data_counter_r) = NUM_DATA_BITS_G-2 or to_integer(data_counter_r) = NUM_DATA_BITS_G-1) then
          if(to_integer(data_counter_r) = NUM_DATA_BITS_G-1) then
            sclk_en_r     <= '0'; -- Disable clock on last cycle

          else
            sclk_en_r     <= '1'; -- Enable clock

          end if;
          sdio_r        <= '0'; -- No output data
          sdio_high_z_r <= '1'; -- Read data
          csn_r         <= '0'; -- Drop CSN

        when SPI_READ_OUT_STATE =>
          sclk_en_r     <= '0'; -- Disable clock
          sdio_r        <= '0'; -- No output data
          sdio_high_z_r <= '0'; -- Drop high-z
          csn_r         <= '1'; -- Let go of CSN

        when SPI_END_STATE =>
          sclk_en_r     <= '0'; -- Disable clock
          sdio_r        <= '0'; -- No output data
          sdio_high_z_r <= '0'; -- Drop high-z
          csn_r         <= '1'; -- Let go of CSN

        when others =>
          sclk_en_r     <= '0'; -- Disable clock
          sdio_r        <= '0'; -- No output data
          sdio_high_z_r <= '0'; -- Drop high-z
          csn_r         <= '1'; -- Let go of CSN
      end case;
    end if;
  end process;


  --------------------------------------
  -- Handle SPI read data message lines
  --------------------------------------
  read_proc: process(spi_clk_in_p)
  begin
    if(rising_edge(spi_clk_in_p)) then
      -- Read SPI data
      if(curr_spi_state_r = SPI_READ_STATE or curr_spi_state_r = SPI_READ_OUT_STATE) then
        spi_read_data_r <= spi_read_data_r(6 downto 0) & sdio_in_p;

      end if;

      -- Read data valid
      if(curr_spi_state_r = SPI_READ_OUT_STATE) then
        spi_data_valid_r <= '1';

      else
        spi_data_valid_r <= '0';

      end if;
    end if;
  end process;




  -- -----------------------------------------------------------------------------
  -- -- Components
  -- -----------------------------------------------------------------------------
  -- u_spi_clk_gate : BUFGCE
  --   generic map (
  --     CE_TYPE        => "SYNC",           -- ASYNC, HARDSYNC, SYNC
  --     IS_CE_INVERTED => '0',              -- Programmable inversion on CE
  --     IS_I_INVERTED  => '0',              -- Programmable inversion on I
  --     SIM_DEVICE     => "ULTRASCALE_PLUS" -- ULTRASCALE, ULTRASCALE_PLUS
  --     )
  --   port map (
  --     O  => sclk_r,      -- 1-bit output: Buffer
  --     CE => sclk_en_r,   -- 1-bit input: Buffer enable
  --     I  => spi_clk_in_p -- 1-bit input: Buffer
  --     );

  -- u_spi_data : IDDRE1
  --   generic map (
  --     DDR_CLK_EDGE   => "OPPOSITE_EDGE", -- IDDRE1 mode (OPPOSITE_EDGE, SAME_EDGE, SAME_EDGE_PIPELINED)
  --     IS_CB_INVERTED => '0',             -- Optional inversion for CB
  --     IS_C_INVERTED  => '0'              -- Optional inversion for C
  --     )
  --   port map (
  --     Q1 => sdio_in_a_r,   -- 1-bit output: Registered parallel output 1
  --     Q2 => sdio_in_b_r,   -- 1-bit output: Registered parallel output 2
  --     C  => spi_clk_in_p,  -- 1-bit input: High-speed clock
  --     CB => spi_clk_in_ns, -- 1-bit input: Inversion of High-speed clock C
  --     D  => sdio_in_p,     -- 1-bit input: Serial Data Input
  --     R  => spi_rst_in_p   -- 1-bit input: Active-High Async Reset
  --     );


end rtl;
