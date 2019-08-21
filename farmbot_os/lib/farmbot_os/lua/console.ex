defmodule FarmbotOS.Lua.Console do
  @moduledoc """
  Entry point for a lua console
  ```
  iex> [Ctrl+G]
  User switch command
  --> s sh
  --> j
  1  {erlang,apply,[#Fun<Elixir.IEx.CLI.1.112225073>,[]]}
  2* {'Elixir.FarmbotOS.Lua.Console',start,[]}
  --> c
  ```
  """

  alias FarmbotOS.Lua.Console.Server

  @doc """
  This is the callback invoked by Erlang's shell when someone presses Ctrl+G
  and types `s Elixir.FarmbotOS.Lua.Console` or `s lua`.
  """
  def start(opts \\ [], mfa \\ {FarmbotOS.Lua.Console, :dont_display_result, []}) do
    spawn(fn ->
      # The shell should not start until the system is up and running.
      case :init.notify_when_started(self()) do
        :started -> :ok
        _ -> :init.wait_until_started()
      end

      :io.setopts(Process.group_leader(), binary: true, encoding: :unicode)

      Server.start(opts, mfa)
    end)
  end

  def dont_display_result, do: "don't display result"
end

defmodule :lua do
  @moduledoc """
  This is a shortcut for invoking `FarmbotOS.Lua.Console` in the Erlang job
  control menu.  The alternative is to type `:Elixir.FarmbotOS.Lua.Console` at
  the `s [shell]` prompt.
  """

  defdelegate start, to: FarmbotOS.Lua.Console
end
