defmodule FarmbotCore.PinBindingWorker.StubGPIOHandler do
  @moduledoc "Stub gpio handler for PinBindings"
  @behaviour FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding
  require Logger
  require FarmbotCore.Logger
  use GenServer

  def start_link(pin_number, fun) do
    GenServer.start_link(__MODULE__, [pin_number, fun], name: name(pin_number))
  end

  FarmbotCore.Logger.report_termination()

  def init([pin_number, fun]) do
    Logger.info("StubBindingHandler init")
    {:ok, %{pin_number: pin_number, fun: fun}}
  end

  def name(pin_number), do: :"#{__MODULE__}.#{pin_number}"
end
