defmodule Farmbot.EasterEggs do
  @moduledoc false
  use Farmbot.Logger

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def force do
    GenServer.call(__MODULE__, :force)
  end

  def init([]) do
    timer = generate_timer(self())
    {:ok, %{timer: timer}}
  end

  def handle_info(:timer, state) do
    %{"nouns" => noun_list, "verbs" => verb_list} = load_data()
    verb = Enum.random(verb_list)
    timer = generate_timer(self())
    nouns = Enum.reduce(noun_list, [], fn(map, acc) ->
      [{key, val}] = Map.to_list(map)
      [{:"#{key}", val} | acc]
    end)
    message = EEx.eval_string(verb, nouns)
    bot_name = Farmbot.Asset.device().name
    Logger.fun 3, Enum.join([bot_name, message], " ")
    {:noreply, %{state | timer: timer}}
  end

  def handle_call(:force, _, state) do
    Process.cancel_timer(state.timer)
    send(self(), :timer)
    {:reply, :ok, %{state | timer: nil}}
  end

  defp load_data do
    Path.join(:code.priv_dir(:farmbot), "easter_eggs.json")
      |> File.read!()
      |> Poison.decode!()
  end

  @ms_in_one_hour 3.6e+6 |> round()
  @ms_in_sixty_hours @ms_in_one_hour * 60

  defp generate_timer(pid) do
    time = Enum.random(@ms_in_one_hour..@ms_in_sixty_hours)
    Process.send_after(pid, :timer, time)
  end
end
