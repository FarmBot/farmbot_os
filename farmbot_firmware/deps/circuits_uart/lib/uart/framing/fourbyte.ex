defmodule Circuits.UART.Framing.FourByte do
  @behaviour Circuits.UART.Framing

  @moduledoc """
  Each message is 4 bytes. This framer doesn't do anything for the transmit
  direction, but for receives, it will collect bytes in batches of 4 before
  sending them up. The user can set up a framer timeout if they don't mind
  partial frames. This can be useful to resyncronize when bytes are dropped.
  """

  def init(_args) do
    {:ok, <<>>}
  end

  def add_framing(data, rx_buffer) when is_binary(data) do
    # No processing - assume the app knows to send the right number of bytes
    {:ok, data, rx_buffer}
  end

  def frame_timeout(rx_buffer) do
    # On a timeout, just return whatever was in the buffer
    {:ok, [rx_buffer], <<>>}
  end

  def flush(:transmit, rx_buffer), do: rx_buffer
  def flush(:receive, _rx_buffer), do: <<>>
  def flush(:both, _rx_buffer), do: <<>>

  def remove_framing(data, rx_buffer) do
    process_data(rx_buffer <> data, [])
  end

  defp process_data(<<message::binary-size(4), rest::binary>>, messages) do
    process_data(rest, messages ++ [message])
  end

  defp process_data(<<>>, messages) do
    {:ok, messages, <<>>}
  end

  defp process_data(partial, messages) do
    {:in_frame, messages, partial}
  end
end
