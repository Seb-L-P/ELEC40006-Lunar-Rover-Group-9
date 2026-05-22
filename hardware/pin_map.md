# Pin Map

Metro M0 pin assignments for the EEELunarRover.

## Reserved by the WINC1500 WiFi shield

Pins **5, 7, 10** (CS, IRQ, RST). Do not use these for anything else.

## Motor driver (dual H-bridge)

Each motor has a direction line and an enable line; the enable line carries the PWM speed signal.

| Signal | Metro pin |
| --- | --- |
| Left motor direction | D12 |
| Left motor enable (PWM) | D6 |
| Right motor direction | D4 |
| Right motor enable (PWM) | D9 |

These match the constants in `../rover_firmware/src/main.cpp`. Verified on hardware: motors driven over WiFi from the operator console.

## Sensors

To be assigned as each analogue subsystem is built. Keep clear of pins 5, 7, 10. Pin 0 (UART RX) is the natural choice for the radio subsystem's decoded serial input.

| Subsystem | Metro pin | Notes |
| --- | --- | --- |
| Radio (age) | D0 (UART RX) | suggested; receives the demodulated UART signal |
| Infrared | D2 | comparator output from the SFH 300 + MCP6292 front end; firmware counts rising edges (see `ir_sensor_build.md`) |
| Ultrasound | TBD | |
| Magnetic | TBD | |
