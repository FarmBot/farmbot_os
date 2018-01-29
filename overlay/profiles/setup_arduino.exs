tty = "/dev/ttyACM1"
Application.put_env(:farmbot, :uart_handler, [tty: tty])
Farmbot.Firmware.UartHandler.AutoDetector.update_fw_handler(Farmbot.Firmware.UartHandler)
