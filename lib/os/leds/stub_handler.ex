defmodule FarmbotOS.Leds.StubHandler do
  @moduledoc false
  @behaviour FarmbotOS.Leds.Handler

  def red(_status), do: nil
  def blue(_status), do: nil
  def green(_status), do: nil
  def yellow(_status), do: nil
  def white1(_status), do: nil
  def white2(_status), do: nil
  def white3(_status), do: nil
  def white4(_status), do: nil
  def white5(_status), do: nil

  def start_link(_args) do
    :ignore
  end
end
