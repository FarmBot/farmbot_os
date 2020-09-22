Application.ensure_all_started(:mimic)

[
  Circuits.UART,
  FarmbotFirmware.UartDefaultAdapter,
  File
]
|> Enum.map(&Mimic.copy/1)

ExUnit.configure(max_cases: 1)
ExUnit.start()
