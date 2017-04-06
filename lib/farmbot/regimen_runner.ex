defmodule Farmbot.RegimenRunner do
  @moduledoc """
    Runs a regimen
  """

  defmodule Item do
    @moduledoc false
    @type t :: %__MODULE__{time_offset: integer,
      sequence: Farmbot.CeleryScript.Ast.t}
    defstruct [:time_offset, :sequence]

    def parse(%{"time_offset" => offset, "sequence" => sequence}) do
      %__MODULE__{time_offset: offset,
        sequence: Farmbot.CeleryScript.Ast.parse(sequence)}
    end
  end

  use GenServer
  use Amnesia
  use Farmbot.Sync.Database
  require Logger

  def start_link(regimen, time) do
    GenServer.start_link(__MODULE__, [regimen, time], name: :"regimen-#{regimen.id}")
  end

  @lint false
  def init([regimen, time]) do
    # parse and sort the regimen items
    items = regimen.regimen_items
      |> Enum.map(&Item.parse(&1))
      |> Enum.sort(&(&1.time_offset <= &2.time_offset))
    first_item = List.first(items)

    if first_item do
      epoch = build_epoch(time)
      first_dt = Timex.shift(epoch, milliseconds: first_item.time_offset)
      timestr = "#{first_dt.month}/#{first_dt.day}/#{first_dt.year} " <>
        "at: #{first_dt.hour}:#{first_dt.minute}"
      Logger.info "your fist item will execute on #{timestr}"
      millisecond_offset = Timex.diff(first_dt, Timex.now(), :milliseconds)
      Process.send_after(self(), :execute, millisecond_offset)
      {:ok, %{epoch: epoch, regimen: %{regimen | regimen_items: items}, next_execution: first_dt}}
    else
      Logger.warn ">> no items on regimen: #{regimen.name}"
      {:ok, %{}}
    end
  end

  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @lint false
  def handle_info(:execute, state) do
    {item, regimen} = pop_item(state.regimen)
    if item do
      Elixir.Sequence.Supervisor.add_child(item.sequence, Timex.now())
      next_item = List.first(regimen.regimen_items)
      if next_item do
        next_dt = Timex.shift(state.epoch, milliseconds: next_item.time_offset)
        timestr = "#{next_dt.month}/#{next_dt.day}/#{next_dt.year} at: #{next_dt.hour}:#{next_dt.minute}"
        Logger.info "your next item will execute on #{timestr}"
        millisecond_offset = Timex.diff(next_dt, Timex.now(), :milliseconds)
        Process.send_after(self(), :execute, millisecond_offset)
        {:ok, %{state | regimen: regimen, next_execution: next_dt}}
      else
        Logger.info ">> #{regimen.name} is complete!"
        spawn fn() ->
          Elixir.Regimen.Supervisor.remove_child(regimen)
        end
        {:noreply, :finished}
      end
    else
      Logger.info ">> #{regimen.name} is complete!"
      spawn fn() ->
        Elixir.Regimen.Supervisor.remove_child(regimen)
      end
      {:noreply, :finished}
    end
  end

  @spec pop_item(Regimen.t) :: {Item.t | nil, Regimen.t}
  # when there is more than one item pop the top one
  defp pop_item(%Regimen{regimen_items: [do_this_one | items ]} = r) do
    {do_this_one, %Regimen{r | regimen_items: items}}
  end

  @doc """
    Gets the state of a regimen by its id.
  """
  def get_state(id), do: GenServer.call(:"regimen-#{id}", :get_state)

  # returns midnight of today
  @spec build_epoch(DateTime.t) :: DateTime.t
  def build_epoch(n) do
    Timex.shift(n, hours: -n.hour, seconds: -n.second, minutes: -n.minute)
  end
end
