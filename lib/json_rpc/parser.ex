defmodule JsonRpc.Parser do
  require Logger
  # notification
  def parse(%{"id" => nil, "method" => method, "params" => params}) do
    %Notification{id: nil, method: method, params: params}
  end

  # Request
  def parse(%{"id" => id, "method" => method, "params" => params}) do
    %Request{id: id, method: method, params: params}
  end

  def parse(%{"result" => result, "error" => error, "id" => id}) do
    %Response{result: result, error: error, id: id}
  end

  def parse(blah) do
    :not_valid
  end

  # JSON RPC RESPONSE
  def ack_msg(id) when is_bitstring(id) do
    Poison.encode!(
    %{id: id,
      error: nil,
      result: %{"OK" => "OK"} })
  end

  # JSON RPC RESPONSE ERROR
  def ack_msg(id, {name, message})
    when is_bitstring(id) and is_bitstring(name)
     and is_bitstring(message)
 do
    Logger.error("RPC ERROR")
    Logger.debug("#{inspect {name, message}}")
    Poison.encode!(
    %{id: id,
      error: %{name: name,
               message: message },
      result: nil})
  end

  @doc """
    Logs a message to the frontend.
  """
  def log_msg(message, channels, tags)
  when is_list(channels)
       and is_list(tags)
       and is_bitstring(message) do
    Poison.encode!(
      %{ id: nil,
         method: "log_message",
         params: [%{ status: Farmbot.BotState.get_status,
                     time: :os.system_time(:seconds),
                     message: message,
                     channels: channels,
                     tags: tags }] })
  end
end
