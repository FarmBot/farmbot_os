defmodule FarmbotOS.Lua.Console.Evaluator do
  @moduledoc """
  The evaluator is responsible for managing the shell port and executing
  commands against it.
  """
  alias FarmbotOS.Lua

  def init(command, server, leader, _opts) do
    old_leader = Process.group_leader()
    Process.group_leader(self(), leader)

    command == :ack && :proc_lib.init_ack(self())
    lua = Lua.init()
    state = %{lua: lua}

    try do
      loop(server, state)
    after
      Process.group_leader(self(), old_leader)
    end
  end

  defp loop(server, state) do
    receive do
      {:eval, ^server, "quit" <> _, _shell_state} ->
        :ok

      {:eval, ^server, command, shell_state} ->
        lua =
          case Lua.do(state.lua, command) do
            {{:error, reason}, lua} ->
              IO.puts("error evaluating: #{inspect(reason)}")
              lua

            {[], lua} ->
              lua

            {return, lua} ->
              {_, lua} = :luerl.call_function([:print], return, lua)
              lua

            error ->
              IO.puts("error evaluating: #{inspect(error)}")
              state.lua
          end

        # If the command changes the shell's directory, there's
        # a chance that this checks too early. In practice, it
        # seems to work for "cd".
        new_shell_state = %{shell_state | counter: shell_state.counter + 1}
        send(server, {:evaled, self(), new_shell_state})
        loop(server, %{state | lua: lua})

      {:done, ^server} ->
        :ok

      other ->
        IO.inspect(other, label: "Unknown message received by lua command evaluator")
        loop(server, state)
    end
  end
end
