defmodule FarmbotCeleryScript.Scheduler.CommandRunner do
  @moduledoc false
  alias FarmbotCeleryScript.RuntimeError
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_args) do
    send(self(), :checkup)
    {:ok, []}
  end

  def handle_cast(steps, state) do
    {:noreply, state ++ steps}
  end

  def handle_info(:checkup, state) do
    # IO.puts "[#{inspect(self())}] CommandRunner checkup"
    {:noreply, [], {:continue, state}}
  end

  def handle_continue([{_timestamp, {pid, ref}, compiled} | rest], state) do
    case step_through(compiled) do
      :ok ->
        send(pid, {FarmbotCeleryScript.Scheduler, ref, :ok})
        {:noreply, state, {:continue, rest}}

      {:error, reason} ->
        send(pid, {FarmbotCeleryScript.Scheduler, ref, {:error, reason}})
        {:noreply, state, {:continue, rest}}
    end
  end

  def handle_continue([], state) do
    # IO.puts "[#{inspect(self())}] CommandRunner complete"
    send(self(), :checkup)
    {:noreply, state}
  end

  defp step_through([fun | rest]) do
    case step(fun) do
      [fun | _] = more when is_function(fun, 0) ->
        step_through(more ++ rest)

      {:error, reason} ->
        {:error, reason}

      _ ->
        step_through(rest)
    end
  end

  defp step_through([]), do: :ok

  def step(fun) when is_function(fun, 0) do
    try do
      IO.inspect(fun, label: "step")
      fun.()
    rescue
      e in RuntimeError -> {:error, Exception.message(e)}
      exception -> reraise(exception, __STACKTRACE__)
    end
  end
end
