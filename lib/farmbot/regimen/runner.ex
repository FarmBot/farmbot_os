defmodule Farmbot.Regimen.Runner do
  @moduledoc """
    Runs a regimen
  """

  alias   Farmbot.Regimen.Supervisor, as: RegSup
  alias   Farmbot.{Database, Context}
  alias   Database.Syncable.{Regimen, Sequence}
  alias   Farmbot.CeleryScript.Command
  use     GenServer
  require Logger

  defmodule Error do
    @moduledoc false
    defexception [:epoch, :regimen, :message]
  end

  defmodule Item do
    @moduledoc false
    @type t :: %__MODULE__{
      name:        binary,
      time_offset: integer,
      sequence:    Farmbot.CeleryScript.Ast.t
    }

    defstruct [:time_offset, :sequence, :name]

    def parse(%{"time_offset" => offset, "sequence_id" => sequence_id},
      %Context{} = ctx)
    do
      sequence = fetch_sequence(ctx, sequence_id)
      %__MODULE__{
        name:        sequence.name,
        time_offset: offset,
        sequence:    Farmbot.CeleryScript.Ast.parse(sequence)}
    end

    def fetch_sequence(%Context{} = ctx, id) do
      db_obj = Database.get_by_id(ctx, Sequence, id)
      unless db_obj do
        raise "Could not find sequence by id: #{inspect id}"
      end
      db_obj.body
    end
  end

  def start_link(%Context{} = ctx, regimen, time) do
    GenServer.start_link(__MODULE__,
      [ctx, regimen, time],
      name: :"regimen-#{regimen.id}")
  end

  def init([ctx, regimen, time]) do
    # parse and sort the regimen items
    items         = filter_items(regimen, ctx)
    first_item    = List.first(items)
    regimen       = %{regimen | regimen_items: items}
    epoch         = build_epoch(ctx, time) || raise Error,
      message: "Could not determine EPOCH because no timezone was supplied.",
      epoch: :error, regimen: regimen

    initial_state = %{
      next_execution: nil,
      regimen:        regimen,
      context:        ctx,
      epoch:          epoch,
      timer:          nil
    }

    if first_item do
      state = build_next_state(regimen, first_item, ctx, self(), initial_state)
      {:ok, state}
    else
      Logger.warn "[#{regimen.name}] has no items on regimen."
      {:ok, :finished}
    end
  end

  def handle_info(:execute, state) do
    {item, regimen} = pop_item(state.regimen)
    if item do
      do_item(item, regimen, state)
    else
      Logger.info "[#{regimen.name}] is complete!"
      spawn fn() ->
        RegSup.remove_child(state.context, regimen)
      end
      {:noreply, :finished}
    end
  end

  def handle_info(:skip, state) do
    {item, regimen} = pop_item(state.regimen)
    if item do
      do_item(nil, regimen, state)
    else
      Logger.info "[#{regimen.name}] is complete!"
      spawn fn() ->
        RegSup.remove_child(state.context, regimen)
      end
      {:noreply, :finished}
    end
  end

  defp filter_items(regimen, %Context{} = ctx) do
    regimen.regimen_items
      |> Enum.map(&Item.parse(&1, ctx))
      |> Enum.sort(&(&1.time_offset <= &2.time_offset))
  end

  defp do_item(item, regimen, state) do
    context =
      if item do
        Logger.info "[#{regimen.name}] is going to execute: #{item.name}"
        Command.do_command(item.sequence, state.context)
      else
        state.context
      end
    next_item = List.first(regimen.regimen_items)
    if next_item do
      new_state = build_next_state(regimen, next_item, context, self(), state)
      {:noreply, new_state}
    else
      Logger.info "[#{regimen.name}] is complete!"
      spawn fn() ->
        RegSup.remove_child(context, regimen)
      end
      {:noreply, :finished}
    end
  end

  def build_next_state(
    %Regimen{} = regimen,
    %Item{} = nx_itm, %Context{} = context,
    pid, state)
  do
    next_dt         = Timex.shift(state.epoch, milliseconds: nx_itm.time_offset)
    now             = Timex.now(Farmbot.BotState.get_config(context, :timezone))
    offset_from_now = Timex.diff(next_dt, now, :milliseconds)

    timer = if (offset_from_now < 0) and (offset_from_now < -60_000) do
      Logger.info "[#{regimen.name}] #{[nx_itm.name]} has been scheduled " <>
        "to happen more than one minute ago: #{offset_from_now} Skipping it."
      Process.send_after(pid, :skip, 1000)
    else
      {msg, real_offset} = ensure_not_negative(offset_from_now)
      Process.send_after(pid, msg, real_offset)
    end

    timestr = "#{next_dt.month}/#{next_dt.day}/#{next_dt.year} " <>
      "at: #{next_dt.hour}:#{next_dt.minute} (#{offset_from_now} milliseconds)"

    Logger.info "[#{regimen.name}] next item will execute on #{timestr}"

    %{state | timer: timer,
      context: context,
      regimen: regimen,
      next_execution: next_dt}
  end

  defp ensure_not_negative(offset) when offset < -60_000, do: {:skip, 1000}
  defp ensure_not_negative(offset) when offset < 0,       do: {:execute, 1000}
  defp ensure_not_negative(offset),                       do: {:execute, offset}

  @spec pop_item(Regimen.t) :: {Item.t | nil, Regimen.t}
  # when there is more than one item pop the top one
  defp pop_item(%Regimen{regimen_items: [do_this_one | items ]} = r) do
    {do_this_one, %Regimen{r | regimen_items: items}}
  end

  # returns midnight of today
  @spec build_epoch(Context.t, DateTime.t) :: DateTime.t
  def build_epoch(%Context{} = context, time) do
    tz = Farmbot.BotState.get_config(context, :timezone)
    if tz do
      n  = Timex.Timezone.convert(time, tz)
      Timex.shift(n, hours: -n.hour, seconds: -n.second, minutes: -n.minute)
    end
  end
end
