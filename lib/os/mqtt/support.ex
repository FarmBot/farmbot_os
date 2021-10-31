defmodule FarmbotOS.MQTT.Support do
  alias FarmbotOS.Leds

  # Dropped message.
  def forward_message(nil, _msg), do: nil

  def forward_message(pid, {topic, message}) when is_pid(pid) do
    Leds.blue(:solid)
    if Process.alive?(pid), do: send(pid, {:inbound, topic, message})
  end

  def forward_message(mod, {topic, message}) do
    forward_message(Process.whereis(mod), {topic, message})
  end
end
