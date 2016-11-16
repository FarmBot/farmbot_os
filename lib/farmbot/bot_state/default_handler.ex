defmodule DefaultHandler do
  use GenEvent
  require Logger

  def init(_), do: {:ok, {}}

  def handle_event(event, state) do
    Logger.info "received event #{inspect event}"

    {:ok, state}
  end
end
