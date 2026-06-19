# 定义 LED 控制模块
defmodule FarmbotOS.SystemLed do
  @led_path "/sys/class/leds/ACT/brightness"

  # 点亮
  def on, do: File.write!(@led_path, "1")

  # 熄灭
  def off, do: File.write!(@led_path, "0")

  # 闪烁
  def blink(ms \\ 500) do
    on()
    Process.sleep(ms)
    off()
  end
end
