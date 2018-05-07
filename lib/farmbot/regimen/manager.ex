defmodule Farmbot.Regimen.Manager do
  @moduledoc "Manages a Regimen"

  use Farmbot.Logger
  use GenServer
  alias Farmbot.CeleryScript
  alias Farmbot.Asset
  alias Asset.Regimen
  import Farmbot.Regimen.NameProvider
  import Farmbot.System.ConfigStorage, only: [
    get_config_value: 3,
  ]

  defmodule Error do
    @moduledoc false
    defexception [:epoch, :regimen, :message]
  end

  defmodule Item do
    @moduledoc false
    @type t :: %__MODULE__{
      name:        binary,
      time_offset: integer,
      sequence:    CeleryScript.AST.t,
      sequence_id: integer,
      ref:         reference
    }

    defstruct [:time_offset, :sequence, :sequence_id, :name, :ref]

    def parse(%{time_offset: offset, sequence_id: sequence_id}) do
      sequence = fetch_sequence(sequence_id)
      {:ok, ast} = CeleryScript.AST.decode(sequence)
      ast_with_label = %{ast | args: Map.put(ast.args, :label, sequence.name)}

      %__MODULE__{
        name:        sequence.name,
        time_offset: offset,
        sequence:    ast_with_label,
        sequence_id: sequence_id,
        ref: make_ref()
      }
    end

    def fetch_sequence(id), do: Asset.get_sequence_by_id!(id)
  end

  def filter_items(regimen) do
    regimen.regimen_items
      |> Enum.map(&Item.parse(&1))
      |> Enum.sort(&(&1.time_offset <= &2.time_offset))
  end

  @doc false
  def start_link(regimen, time) do
    regimen.farm_event_id || raise "Starting a regimen requires a farm_event id"
    GenServer.start_link(__MODULE__, [regimen, time], name: via(regimen))
  end

  def init([regimen, time]) do
    # parse and sort the regimen items
    items         = filter_items(regimen)
    first_item    = List.first(items)
    regimen       = %{regimen | regimen_items: items}
    epoch         = Farmbot.TimeUtils.build_epoch(time) || raise Error,
      message: "Could not determine EPOCH because no timezone was supplied.",
      epoch: :error, regimen: regimen

    initial_state = %{
      next_execution: nil,
      regimen:        regimen,
      epoch:          epoch,
      timer:          nil
    }

    if first_item do
      state = build_next_state(regimen, first_item, self(), initial_state)
      {:ok, state}
    else
      Logger.warn 2, "[#{regimen.name} #{regimen.farm_event_id}] has no items on regimen."
      {:ok, initial_state}
    end
  end

  def handle_call({:reindex, regimen, time}, _from, state) do
    Logger.debug 3, "Reindexing regimen by id: #{regimen.id}"
    regimen.farm_event_id || raise "Can't reindex without farm_event_id"
    # parse and sort the regimen items
    items         = filter_items(regimen)
    first_item    = List.first(items)
    regimen       = %{regimen | regimen_items: items}
    epoch         = if time, do: Farmbot.TimeUtils.build_epoch(time), else: state.epoch

    initial_state = %{
      regimen:        regimen,
      epoch:          epoch,
      # Leave these so they get cleaned up
      next_execution: state.next_execution,
      timer:          state.timer
    }

    if first_item do
      state = build_next_state(regimen, first_item, self(), initial_state)
      {:reply, :ok, state}
    else
      Logger.warn 2, "[#{regimen.name} #{regimen.farm_event_id}] has no items on regimen."
      {:reply, :ok, initial_state}
    end
  end

  def handle_info(:execute, state) do
    {item, regimen} = pop_item(state.regimen)
    if item do
      do_item(item, regimen, state)
    else
      complete(regimen, state)
    end
  end

  def handle_info(:skip, state) do
    {item, regimen} = pop_item(state.regimen)
    if item do
      do_item(nil, regimen, state)
    else
      complete(regimen, state)
    end
  end

  defp complete(regimen, state) do
    Logger.success 2, "[#{regimen.name} #{regimen.farm_event_id}] has executed all current items!"
    items         = filter_items(state.regimen)
    regimen       = %{state.regimen | regimen_items: items}
    {:noreply, %{state | regimen: regimen}}
  end

  defp do_item(item, regimen, state) do
    if item do
      Logger.busy 2, "[#{regimen.name} #{regimen.farm_event_id}] is going to execute: #{item.name}"
      CeleryScript.execute(item.sequence)
    end
    next_item = List.first(regimen.regimen_items)
    if next_item do
      new_state = build_next_state(regimen, next_item, self(), state)
      {:noreply, new_state}
    else
      complete(regimen, state)
    end
  end

  def build_next_state(
    %Regimen{} = regimen,
    %Item{} = nx_itm,
    pid, state)
  do
    if state.timer do
      Process.cancel_timer(state.timer)
    end
    next_dt         = Timex.shift(state.epoch, milliseconds: nx_itm.time_offset)
    timezone        = get_config_value(:string, "settings", "timezone")
    now             = Timex.now(timezone)
    offset_from_now = Timex.diff(next_dt, now, :milliseconds)

    timer = if (offset_from_now < 0) and (offset_from_now < -60_000) do
      Process.send_after(pid, :skip, 1000)
    else
      {msg, real_offset} = ensure_not_negative(offset_from_now)
      Process.send_after(pid, msg, real_offset)
    end

    if offset_from_now > 0 do
      timestr = Farmbot.TimeUtils.format_time(next_dt)
      from_now = Timex.from_now(next_dt, Farmbot.Asset.device.timezone)
      msg = "[#{regimen.name}] scheduled by FarmEvent (#{regimen.farm_event_id}) " <>
        "will execute next item #{from_now} (#{timestr})"

      Logger.info 3, msg
    end

    %{state | timer: timer,
      regimen: regimen,
      next_execution: next_dt}
  end

  defp ensure_not_negative(offset) when offset < -60_000, do: {:skip, 1000}
  defp ensure_not_negative(offset) when offset < 0,       do: {:execute, 1000}
  defp ensure_not_negative(offset),                       do: {:execute, offset}

  @spec pop_item(Regimen.t) :: {Item.t | nil, Regimen.t}
  # when there is more than one item pop the top one
  defp pop_item(%Regimen{regimen_items: [do_this_one | items]} = r) do
    {do_this_one, %Regimen{r | regimen_items: items}}
  end
end
