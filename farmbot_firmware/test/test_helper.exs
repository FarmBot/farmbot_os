Application.ensure_all_started(:mimic)
Mimic.copy(FarmbotFirmware.UartDefaultAdapter)
ExUnit.start()
