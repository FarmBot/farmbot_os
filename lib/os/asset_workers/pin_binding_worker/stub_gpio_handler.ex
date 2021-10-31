defmodule FarmbotOS.PinBindingWorker.StubGPIOHandler do
  @moduledoc "Stub gpio handler for PinBindings"
  @behaviour FarmbotOS.AssetWorker.FarmbotOS.Asset.PinBinding
  require Logger
  require FarmbotOS.Logger
  use GenServer

  def start_link(pin_number, fun) do
    GenServer.start_link(__MODULE__, [pin_number, fun], name: name(pin_number))
  end

  FarmbotOS.Logger.report_termination()

  def init([pin_number, fun]) do
    Logger.info("StubBindingHandler init")
    {:ok, %{pin_number: pin_number, fun: fun}}
  end

  def name(pin_number), do: :"#{__MODULE__}.#{pin_number}"
end
