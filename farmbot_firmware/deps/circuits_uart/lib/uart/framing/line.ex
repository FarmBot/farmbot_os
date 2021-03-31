defmodule Circuits.UART.Framing.Line do
  @behaviour Circuits.UART.Framing

  @moduledoc """
  Each message is one line. This framer appends and removes newline sequences
  as part of the framing. Buffering is performed internally, so users can get
  the complete messages under normal circumstances. Attention should be paid
  to the following:

  1. Lines must have a fixed max length so that a misbehaving sender can't
     cause unbounded buffer expansion. When the max length is passed, a
     `{:partial, data}` is reported. The application can decide what to do with
     this.
  2. The separation character varies depending on the target device. See
     "Separator" section to see how to specify this.
  3. It may be desirable to set a `:rx_framer_timeout` to prevent
     characters received in error from collecting during idle times. When the
     receive timer expires, `{:partial, data}` is reported.
  4. Line separators must be ASCII characters (0-127) or be valid UTF-8
     sequences. If the device only sends ASCII, high characters (128-255)
     should work as well. [Note: please report if using extended
     characters.]

  ## Separator

  Some devices require `"\\r\\n"` sequences. If you are using one of these
  devices, a LTE modem for example, you can specify the separator like so:

  ```elixir
  Circuits.UART.open(uart, tty_name, framing: {Line, separator: "\\r\\n"})
  ```

  By default the separator is `"\\n"`. Currently only one or two character
  separators are supported.
  """

  defmodule State do
    @moduledoc false
    defstruct max_length: nil, separator: nil, processed: <<>>, in_process: <<>>
  end

  def init(args) do
    max_length = Keyword.get(args, :max_length, 4096)
    separator = Keyword.get(args, :separator, "\n")

    state = %State{max_length: max_length, separator: separator}
    {:ok, state}
  end

  def add_framing(data, state) do
    {:ok, data <> state.separator, state}
  end

  def remove_framing(data, state) do
    {new_processed, new_in_process, lines} =
      process_data(
        state.separator,
        byte_size(state.separator),
        state.max_length,
        state.processed,
        state.in_process <> data,
        []
      )

    new_state = %{state | processed: new_processed, in_process: new_in_process}
    rc = if buffer_empty?(new_state), do: :ok, else: :in_frame
    {rc, lines, new_state}
  end

  def frame_timeout(state) do
    partial_line = {:partial, state.processed <> state.in_process}
    new_state = %{state | processed: <<>>, in_process: <<>>}
    {:ok, [partial_line], new_state}
  end

  def flush(direction, state) when direction == :receive or direction == :both do
    %{state | processed: <<>>, in_process: <<>>}
  end

  def flush(:transmit, state) do
    state
  end

  def buffer_empty?(%State{processed: <<>>, in_process: <<>>}), do: true
  def buffer_empty?(_state), do: false

  # Handle not enough data case
  defp process_data(_separator, sep_length, _max_length, processed, to_process, lines)
       when byte_size(to_process) < sep_length do
    {processed, to_process, lines}
  end

  # Process data until separator or next char
  defp process_data(separator, sep_length, max_length, processed, to_process, lines) do
    case to_process do
      # Handle separater
      <<^separator::binary-size(sep_length), rest::binary>> ->
        new_lines = lines ++ [processed]
        process_data(separator, sep_length, max_length, <<>>, rest, new_lines)

      # Handle line too long case
      to_process
      when byte_size(processed) == max_length and to_process != <<>> ->
        new_lines = lines ++ [{:partial, processed}]
        process_data(separator, sep_length, max_length, <<>>, to_process, new_lines)

      # Handle next char
      <<next_char::binary-size(1), rest::binary>> ->
        process_data(separator, sep_length, max_length, processed <> next_char, rest, lines)
    end
  end
end
