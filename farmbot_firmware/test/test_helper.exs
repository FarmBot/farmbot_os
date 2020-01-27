Application.ensure_all_started(:mimic)
Mimic.copy(FarmbotFirmware.UartDefaultAdapter)
Mimic.copy(Circuits.UART)
ExUnit.start()
