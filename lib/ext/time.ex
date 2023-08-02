# FarmbotOS.Time.no_reply()
defmodule FarmbotOS.Time do
  @conf Application.compile_env(:farmbot, __MODULE__) || []
  @disabled Keyword.get(@conf, :disable_timeouts, false)

  @doc """
  A wrapper around `Process.send_after` for simplified dep. injection.
  If this function is called in `test` ENV, it will send the
  message immediately without a timeout.

  All other ENVs delegate to `Process.send_after/3)
  """
  def send_after(pid, message, timeout) do
    Process.send_after(pid, message, ms(timeout))
  end

  def no_reply(state, timeout) do
    {:noreply, state, ms(timeout)}
  end

  def sleep(num) do
    Process.sleep(ms(num))
  end

  def cancel_timer(nil), do: nil
  def cancel_timer(ref), do: Process.cancel_timer(ref)

  def ms(num) do
    if @disabled, do: 0, else: num
  end

  def system_time_ms, do: :os.system_time(:millisecond)
end
