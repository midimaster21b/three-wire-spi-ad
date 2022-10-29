# Analog Digital Three Wire SPI (AN-877)

This project was initially made to interface with the Analog Digital AD9467 ADC.

The application note can be found [here](https://www.analog.com/AN-877?doc=AD9670).

## SPI Specifications

- 3-wire SPI
- SCLK may stall either low or high
- Input data is registered on the rising edge of SCLK
- Output data is is registered on the falling edge of SCLK
- Maximum clock speed: 25 MHz
- Typical hold time of 0 ns
- Minimum setup time of 5 ns between SCLK and SDIO
- Active low chip select



### Serial Clock (SCLK)

- The SCLK pin is the serial shift clock in pin


### Serial Data Input/Output (SDIO)

- All Analog Digital ADC devices using the three-wire SPI interface are capable
  of changing the state(input/high-z to output) of the SDIO signal in half of
  an SCLK cycle in the the transition from address to data phase during a read
  operation.

- FROM THE DOCUMENTATION:

  ```
  To optimize internal and external timing, the bus is capable of turning around
  the state of the SDIO line in half an SCLK cycle. This means that, after the
  address information is passed to the converter requesting a read, the SDIO
  line is transitioned from an input to an output within one half of a clock
  cycle. This ensures that by the time the falling edge of the next clock cycle
  occurs, data can be safely placed on this serial line for the controller to
  read. If the external controller is insufficiently fast to keep up with the
  ADC SPI port, the external device can stall the clock line to add additional
  time allowing for external timing issues.
  ```

- The SDIO will not become an output(from the ADC's perspective) during read
  operations if the ADC has an SDO port **__AND__** the register set is configured to
  use the SDO port.


### Chip Select Bar (CSB)

- Active low
- Tying this port high prevents the device from being reset
- Can be tied high to enable secondary function of the SPI port

- FROM THE DOCS:

  ```
  For applications to be controlled by the SPI port, the secondary function
  takes priority until the device has been accessed by the SPI port. By
  extension, any activity on the SCLK, SDIO, and SDO (if provided) is
  interpreted as a secondary function until the chip has been accessed by the
  SPI port. Therefore, the chip needs to be initialized as soon after power up
  as practical. (See the Detection of SPI Mode and Pin Mode section for more
  details.)
  ```

