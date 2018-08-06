defmodule Farmbot.CeleryScript.RunTime.InstructionSet do
  @moduledoc """
  Implementation for each and every executable CeleryScript AST node.
  """

  alias Farmbot.CeleryScript.RunTime.{
    FarmProc,
    Instruction,
    SysCallHandler,
    Resolver
  }

  alias Farmbot.CeleryScript.AST
  import Farmbot.CeleryScript.Utils
  import Instruction, only: [simple_io_instruction: 1]
  import SysCallHandler, only: [apply_sys_call_fun: 2]

  import FarmProc,
    only: [
      get_pc_ptr: 1,
      get_next_address: 2,
      get_body_address: 2,
      get_cell_attr_as_pointer: 3,
      pop_rs: 1,
      push_rs: 2,
      set_pc_ptr: 2,
      set_status: 2,
      set_crash_reason: 2,
      clear_io_result: 1,
      set_io_latch: 2,
      get_heap_by_page_index: 2,
      new_page: 3,
      get_zero_page: 1,
      is_null_address?: 1
    ]

  # Command Nodes
  @doc "Write a pin."
  simple_io_instruction(:write_pin)

  @doc "Read a pin."
  simple_io_instruction(:read_pin)

  @doc "Write servo pin value."
  simple_io_instruction(:set_servo_angle)

  @doc "Send a message."
  simple_io_instruction(:send_message)

  @doc "move relative to the bot's current position."
  simple_io_instruction(:move_relative)

  @doc "Move an axis home."
  simple_io_instruction(:home)

  @doc "Find an axis home."
  simple_io_instruction(:find_home)

  @doc "Wait (block) a number of milliseconds."
  simple_io_instruction(:wait)

  @doc "Toggle a pin atomicly."
  simple_io_instruction(:toggle_pin)

  @doc "Force axis position to become zero."
  simple_io_instruction(:zero)

  @doc "Calibrate an axis."
  simple_io_instruction(:calibrate)

  @doc "Execute `take_photo` Farmware if installed."
  simple_io_instruction(:take_photo)

  # RPC Nodes

  @doc "Update bot or firmware configuration."
  simple_io_instruction(:config_update)

  @doc "Set environment variables for a Farmware."
  simple_io_instruction(:set_user_env)

  @doc "(Re)Install Farmware written and developed by Farmbot, Inc."
  simple_io_instruction(:install_first_party_farmware)

  @doc "Install a Farmware from the web."
  simple_io_instruction(:install_farmware)

  @doc "Remove a Farmware."
  simple_io_instruction(:remove_farmware)

  @doc "Update a Farmware."
  simple_io_instruction(:update_farmware)

  @doc "Force the bot's state to be dispatched."
  simple_io_instruction(:read_status)

  @doc "Sync all resources with the Farmbot Web Application."
  simple_io_instruction(:sync)

  @doc "Power the bot down."
  simple_io_instruction(:power_off)

  @doc "Reboot the bot."
  simple_io_instruction(:reboot)

  @doc "Factory reset the bot allowing for reconfiguration."
  simple_io_instruction(:factory_reset)

  @doc "Factory reset the bot, but supply new credentials without reconfiguration."
  simple_io_instruction(:change_ownership)

  @doc "Check for OS updates."
  simple_io_instruction(:check_updates)

  @doc "Create a diagnostic dump of information."
  simple_io_instruction(:dump_info)

  @doc "Move to a location offset by another location."
  def move_absolute(%FarmProc{} = farm_proc) do
    pc = get_pc_ptr(farm_proc)
    heap = get_heap_by_page_index(farm_proc, pc.page_address)
    data = AST.unslice(heap, pc.heap_address)

    data = case data.args.location do
      %AST{kind: :identifier} ->
        location = Resolver.resolve(farm_proc, pc, data.args.location.args.label)
        %{data | args: %{data.args | location: location}}
      _ -> data
    end

    data = case data.args.offset do
      %AST{kind: :identifier} ->
        offset = Resolver.resolve(farm_proc, pc, data.args.offset.args.label)
        %{data | args: %{data.args | offset: offset}}
      _ -> data
    end

    case farm_proc.io_result do
      # If we need to lookup a coordinate, do that.
      # We will come back to {:ok, ast} or {:error, reason}
      # next iteration.
      # Or if we didn't need to lookup a coordinate, just execute `move_absolute`
      # and come back to `:ok` or `{:error, reason}`
      nil ->
        latch = apply_sys_call_fun(farm_proc.sys_call_fun, data)

        farm_proc
        |> set_status(:waiting)
        |> set_io_latch(latch)

      # Result of coordinate lookup.
      # This starts the actual movement.
      {:ok, %AST{} = result} ->
        args = AST.new(:move_absolute, %{location: result, offset: data.args.offset}, [])
        latch = apply_sys_call_fun(farm_proc.sys_call_fun, args)

        farm_proc
        |> set_status(:waiting)
        |> set_io_latch(latch)

      # Result of _actual_ movement.
      :ok ->
        next_or_return(farm_proc)

      {:error, reason} ->
        crash(farm_proc, reason)

      other ->
        exception(farm_proc, "Bad return value handling move_absolute IO: #{inspect(other)}")
    end
  end

  def rpc_request(%FarmProc{} = farm_proc) do
    sequence(farm_proc)
  end

  @doc "Execute a sequeence."
  @spec sequence(FarmProc.t()) :: FarmProc.t()
  def sequence(%FarmProc{} = farm_proc) do
    pc_ptr = get_pc_ptr(farm_proc)
    body_addr = get_body_address(farm_proc, pc_ptr)

    if is_null_address?(body_addr),
      do: return(farm_proc),
      else: call(farm_proc, body_addr)
  end

  @doc "Conditionally execute a sequence."
  @spec _if(FarmProc.t()) :: FarmProc.t()
  def _if(%FarmProc{io_result: nil} = farm_proc) do
    pc = get_pc_ptr(farm_proc)
    heap = get_heap_by_page_index(farm_proc, pc.page_address)
    data = Farmbot.CeleryScript.AST.Unslicer.run(heap, pc.heap_address)
    latch = apply_sys_call_fun(farm_proc.sys_call_fun, data)

    farm_proc
    |> set_status(:waiting)
    |> set_io_latch(latch)
  end

  def _if(%FarmProc{io_result: result} = farm_proc) do
    pc = get_pc_ptr(farm_proc)

    case result do
      {:ok, true} ->
        farm_proc
        |> set_pc_ptr(get_cell_attr_as_pointer(farm_proc, pc, :___then))
        |> clear_io_result()

      {:ok, false} ->
        farm_proc
        |> set_pc_ptr(get_cell_attr_as_pointer(farm_proc, pc, :___else))
        |> clear_io_result()

      :ok ->
        exception(farm_proc, "Bad _if implementation.")

      {:error, reason} ->
        crash(farm_proc, reason)
    end
  end

  @doc "Do nothing. Triggers `status` to be set to `done`."
  @spec nothing(FarmProc.t()) :: FarmProc.t()
  def nothing(%FarmProc{} = farm_proc) do
    next_or_return(farm_proc)
  end

  @doc "Lookup and execute another sequence."
  @spec execute(FarmProc.t()) :: FarmProc.t()
  def execute(%FarmProc{io_result: nil} = farm_proc) do
    pc = get_pc_ptr(farm_proc)
    heap = get_heap_by_page_index(farm_proc, pc.page_address)
    sequence_id = FarmProc.get_cell_attr(farm_proc, pc, :sequence_id)
    next_ptr = get_next_address(farm_proc, pc)

    if FarmProc.has_page?(farm_proc, addr(sequence_id)) do
      farm_proc
      |> push_rs(next_ptr)
      |> set_pc_ptr(ptr(sequence_id, 1))
    else
      # Step 0: Unslice current address.
      data = AST.unslice(heap, pc.heap_address)
      latch = apply_sys_call_fun(farm_proc.sys_call_fun, data)

      farm_proc
      |> set_status(:waiting)
      |> set_io_latch(latch)
    end
  end

  def execute(%FarmProc{io_result: result} = farm_proc) do
    pc = get_pc_ptr(farm_proc)
    sequence_id = FarmProc.get_cell_attr(farm_proc, pc, :sequence_id)
    next_ptr = get_next_address(farm_proc, pc)
    # Step 1: Get a copy of the sequence.
    case result do
      {:ok, %AST{} = sequence} ->
        # Step 2: Push PC -> RS
        # Step 3: Slice it
        new_heap = AST.slice(sequence)
        seq_addr = addr(sequence_id)
        seq_ptr = ptr(sequence_id, 1)

        push_rs(farm_proc, next_ptr)
        # Step 4: Add the new page.
        |> new_page(seq_addr, new_heap)
        # Step 5: Set PC to Ptr(1, 1)
        |> set_pc_ptr(seq_ptr)
        |> clear_io_result()

      {:error, reason} ->
        crash(farm_proc, reason)

      _ ->
        exception(farm_proc, "Bad execute implementation.")
    end
  end

  def execute_script(%FarmProc{io_result: nil} = farm_proc) do
    pc = get_pc_ptr(farm_proc)
    heap = get_heap_by_page_index(farm_proc, pc.page_address)

    # Step 0: Unslice current address.
    data = AST.unslice(heap, pc.heap_address)
    latch = apply_sys_call_fun(farm_proc.sys_call_fun, data)

    farm_proc
    |> set_status(:waiting)
    |> set_io_latch(latch)
  end

  def execute_script(%FarmProc{io_result: result} = farm_proc) do
    pc = get_pc_ptr(farm_proc)
    package = FarmProc.get_cell_attr(farm_proc, pc, :package) |> :erlang.crc32()
    next_ptr = get_next_address(farm_proc, pc)
    # Step 1: Get a copy of the sequence.
    case result do
      {:ok, %AST{} = sequence} ->
        # Step 2: Push PC -> RS
        # Step 3: Slice it
        new_heap = AST.slice(sequence)
        seq_addr = addr(package)
        seq_ptr = ptr(package, 1)

        push_rs(farm_proc, pc)
        # Step 4: Add the new page.
        |> new_page(seq_addr, new_heap)
        # Step 5: Set PC to Ptr(1, 1)
        |> set_pc_ptr(seq_ptr)
        |> clear_io_result()

      {:error, reason} ->
        crash(farm_proc, reason)
      :ok ->
        farm_proc
        |> clear_io_result()
        |> set_pc_ptr(next_ptr)
      _data ->
        exception(farm_proc, "Bad execute_script implementation.")
    end
  end

  ## Private

  @spec call(FarmProc.t(), Pointer.t()) :: FarmProc.t()
  defp call(%FarmProc{} = farm_proc, %Pointer{} = address) do
    current_pc = get_pc_ptr(farm_proc)
    next_ptr = get_next_address(farm_proc, current_pc)

    farm_proc
    |> push_rs(next_ptr)
    |> set_pc_ptr(address)
  end

  @spec return(FarmProc.t()) :: FarmProc.t()
  defp return(%FarmProc{} = farm_proc) do
    {value, farm_proc} = pop_rs(farm_proc)
    farm_proc
    |> set_pc_ptr(value)
    |> set_status(:ok)
  end

  @spec next(FarmProc.t()) :: FarmProc.t()
  defp next(%FarmProc{} = farm_proc) do
    current_pc = get_pc_ptr(farm_proc)
    next_ptr = get_next_address(farm_proc, current_pc)
    farm_proc
    |> set_pc_ptr(next_ptr)
    |> set_status(:ok)
  end

  @spec next_or_return(FarmProc.t()) :: FarmProc.t()
  defp next_or_return(farm_proc) do
    pc_ptr = get_pc_ptr(farm_proc)
    addr = get_next_address(farm_proc, pc_ptr)
    farm_proc = clear_io_result(farm_proc)

    is_null_address? = is_null_address?(addr)
    return_stack_is_empty? = farm_proc.rs == []
    cond do
      is_null_address? && return_stack_is_empty? -> set_status(farm_proc, :done)
      is_null_address? -> return(farm_proc)
      !is_null_address? -> next(farm_proc)
    end
  end

  @spec crash(FarmProc.t(), String.t()) :: FarmProc.t()
  defp crash(farm_proc, reason) do
    crash_address = get_pc_ptr(farm_proc)
    zero_page_ptr = get_zero_page(farm_proc) |> Pointer.null()
    # Push PC -> RS
    farm_proc
    |> push_rs(crash_address)
    # set PC to 0,0
    |> set_pc_ptr(zero_page_ptr)
    # Set status to crashed, return the farmproc
    |> set_status(:crashed)
    |> set_crash_reason(reason)
  end
end
