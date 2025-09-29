defmodule FarmbotOS.APTrigger do
  @moduledoc """
  通过 GPIO 引脚触发进入 AP 模式。

  - 默认使用 GPIO26 (BCM 编号)，可在 @gpio_pin 修改。
  - 检测到按键低电平（falling edge）时，进入 AP 模式。
  - LED 闪烁表示触发。
  - 防止重复触发。
  """

  use GenServer
  require FarmbotOS.Logger

  @gpio_pin 26
  @led_flash_ms 500

  # 启动 GenServer
  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    # 打开 GPIO 输入模式
    {:ok, gpio} = Circuits.GPIO.open(@gpio_pin, :input)
    # 设置上拉
    :ok = Circuits.GPIO.set_pull_mode(gpio, :pullup)
    # 设置下降沿触发
    Circuits.GPIO.set_interrupts(gpio, :falling)

    IO.puts("APTrigger: 监听 GPIO#{@gpio_pin}，低电平触发进入 AP 模式。")
    FarmbotOS.Logger.debug(1, "APTrigger: 监听 GPIO#{@gpio_pin}，低电平触发进入 AP 模式。")

    # first 表示第一次触发
    # processing 表示正在处理
    {:ok, %{gpio: gpio, first: true, processing: false}}
  end

  # 防止重复触发：如果正在处理，忽略新消息
  @impl true
  def handle_info({:circuits_gpio, pin, ts, 0}, %{processing: true} = state) do
    IO.puts("GPIO #{pin} 触发被忽略，正在处理上一条触发,ts=#{ts}")
    {:noreply, state}
  end

  # 第一次正常触发
  @impl true
  def handle_info({:circuits_gpio, pin, ts, 0}, %{first: true} = state) do
    IO.puts("GPIO #{pin} 触发消息到达 APTrigger, 第一次!, ts=#{ts}")
    FarmbotOS.Logger.debug(1, "APTrigger: GPIO #{pin} 触发 → 进入 AP 模式。")

    # 设置正在处理标记
    new_state = %{state | first: false, processing: true}

    # 异步执行 factory_reset，同时闪烁 LED
    Task.start(fn ->
      # LED 闪烁一次
      FarmbotOS.SystemLed.on()
      Process.sleep(@led_flash_ms)
      FarmbotOS.SystemLed.off()

      # 执行出厂重置
      FarmbotOS.System.factory_reset("GPIO trigger", true)

      # 通知 GenServer 完成处理
      GenServer.cast(__MODULE__, :done)
    end)

    {:noreply, new_state}
  end

  # 处理完成后，清除 processing 标记
  @impl true
  def handle_cast(:done, state) do
    {:noreply, %{state | processing: false}}
  end

  # 其他 GPIO 消息
  # @impl true
  # def handle_info(msg, state) do
  #   IO.inspect(msg, label: "APTrigger 收到其他消息")
  #   {:noreply, state}
  # end
end
