# Starting FarmbotOS in `host` env

Certain behaviour is slightly different when developing on `host` compared to
deploying on target environments such as `rpi` or `rpi3`.

## Firmware

By default, an Arduino does _not_ need to be connected to your `host` pc when
doing development. See the `FarmbotFirmware.Transport` module for more info
on this topic. If you want to use a real Arduino in `host` mode, you can
export a `FARMBOT_TTY` environment variable in your `host` environment.

```bash
cd farmbot_os
export FARMBOT_TTY=/dev/ttySomeDeviceFile
mix compile --force
```

If your device moves ttys, you will have to redo this step.
Make sure the correct firmware is selected in the frontend. This
value is completely ignored when the `none` option is selected on
the Devices panel.

To check the currently running firmware handler, from a running fbos instance
for the correct `transport` and correct `device` in it's args:

```elixir
iex()> :sys.get_state(FarmbotFirmware)
%FarmbotFirmware{
  #...
  transport: FarmbotFirmware.UARTTransport,
  transport_args: [
    handle_gcode: #Function<1.52136448/1 in FarmbotFirmware.handle_call/3>,
    device: "ttyUSB0"
  ]
  #...
}
```

## Configurator

Currently configurator does not run on the `host` environment. To connect to
your FarmBot account, export the following variables:

```bash
cd farmbot_os
export FARMBOT_EMAIL=test@test.com
export FARMBOT_PASSWORD=password123
export FARMBOT_SERVER=http://localhost:3000
```
