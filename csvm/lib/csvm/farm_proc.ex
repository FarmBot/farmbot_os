defmodule Csvm.FarmProc do
  alias Csvm.{
    AST,
    FarmProc,
    SysCallHandler,
    InstructionSet
  }

  import Csvm.Utils
  alias AST.Heap

  @max_reduction_count 1000

  defstruct sys_call_fun: nil,
            zero_page: nil,
            reduction_count: 0,
            pc: nil,
            rs: [],
            io_latch: nil,
            io_result: nil,
            crash_reason: nil,
            status: :ok,
            heap: %{},
            ref: nil

  @typedoc "Program counter"
  @type heap_address :: Address.t()

  @typedoc "Page address register"
  @type page :: Address.t()

  @typedoc "Possible values of the status attribute."
  @type status_enum :: :ok | :done | :crashed | :waiting

  @type t :: %FarmProc{
          ref: reference(),
          crash_reason: nil | String.t(),
          heap: %{Address.t() => Heap.t()},
          io_latch: nil | pid,
          io_result: nil | any,
          pc: Pointer.t(),
          reduction_count: 0 | pos_integer(),
          rs: [Pointer.t()],
          status: status_enum(),
          sys_call_fun: Csvm.SysCallHandler.sys_call_fun(),
          zero_page: Address.t()
        }

  @typedoc false
  @type new :: %Csvm.FarmProc{
          ref: reference(),
          crash_reason: nil,
          heap: %{Address.t() => Heap.t()},
          io_latch: nil,
          io_result: nil,
          pc: Pointer.t(),
          reduction_count: 0,
          rs: [],
          status: :ok,
          sys_call_fun: Csvm.SysCallHandler.sys_call_fun(),
          zero_page: Address.t()
        }

  @spec new(Csvm.SysCallHandler.sys_call_fun(), page, Heap.t()) :: new()
  def new(sys_call_fun, %Address{} = page, %Heap{} = heap)
      when is_function(sys_call_fun) do
    pc = Pointer.new(page, addr(1))

    %FarmProc{
      ref: make_ref(),
      status: :ok,
      zero_page: page,
      pc: pc,
      sys_call_fun: sys_call_fun,
      heap: %{page => heap}
    }
  end

  @spec new_page(FarmProc.t(), page, Heap.t()) :: FarmProc.t()
  def new_page(
        %FarmProc{} = farm_proc,
        %Address{} = page_num,
        %Heap{} = heap_contents
      ) do
    new_heap = Map.put(farm_proc.heap, page_num, heap_contents)
    %FarmProc{farm_proc | heap: new_heap}
  end

  @spec get_zero_page(FarmProc.t()) :: page
  def get_zero_page(%FarmProc{} = farm_proc),
    do: farm_proc.zero_page

  @spec has_page?(FarmProc.t(), page) :: boolean()
  def has_page?(%FarmProc{} = farm_proc, %Address{} = page),
    do: Map.has_key?(farm_proc.heap, page)

  @spec step(FarmProc.t()) :: FarmProc.t() | no_return
  def step(%FarmProc{status: :crashed} = farm_proc),
    do: exception(farm_proc, "Tried to step with crashed process!")

  def step(%FarmProc{reduction_count: c} = proc) when c >= @max_reduction_count,
    do: exception(proc, "Too many reductions!")

  def step(%FarmProc{status: :waiting} = farm_proc) do
    case SysCallHandler.get_status(farm_proc.io_latch) do
      :ok ->
        farm_proc

      :complete ->
        io_result = SysCallHandler.get_results(farm_proc.io_latch)

        set_status(farm_proc, :ok)
        |> set_io_latch_result(io_result)
        |> remove_io_latch()
        |> step()
    end
  end

  def step(%FarmProc{} = farm_proc) do
    pc_ptr = get_pc_ptr(farm_proc)
    kind = get_kind(farm_proc, pc_ptr)

    # TODO Connor 07-31-2018: why do i have to load the module here?
    available? =
      Code.ensure_loaded?(InstructionSet) and
        function_exported?(InstructionSet, kind, 1)

    unless available? do
      exception(farm_proc, "No implementation for: #{kind}")
    end

    farm_proc = %FarmProc{
      farm_proc
      | reduction_count: farm_proc.reduction_count + 1
    }

    # IO.puts "executing: [#{pc_ptr.page_address}, #{inspect pc_ptr.heap_address}] #{kind}"
    apply(InstructionSet, kind, [farm_proc])
  end

  @spec get_pc_ptr(FarmProc.t()) :: Pointer.t()
  def get_pc_ptr(%FarmProc{pc: pc}), do: pc

  @spec set_pc_ptr(FarmProc.t(), Pointer.t()) :: FarmProc.t()
  def set_pc_ptr(%FarmProc{} = farm_proc, %Pointer{} = pc),
    do: %FarmProc{farm_proc | pc: pc}

  def set_io_latch(%FarmProc{} = farm_proc, pid) when is_pid(pid),
    do: %FarmProc{farm_proc | io_latch: pid}

  def set_io_latch_result(%FarmProc{} = farm_proc, result),
    do: %FarmProc{farm_proc | io_result: result}

  @spec clear_io_result(FarmProc.t()) :: FarmProc.t()
  def clear_io_result(%FarmProc{} = farm_proc),
    do: %FarmProc{farm_proc | io_result: nil}

  @spec remove_io_latch(FarmProc.t()) :: FarmProc.t()
  def remove_io_latch(%FarmProc{} = farm_proc),
    do: %FarmProc{farm_proc | io_latch: nil}

  @spec get_heap_by_page_index(FarmProc.t(), page) :: Heap.t() | no_return
  def get_heap_by_page_index(%FarmProc{heap: heap} = proc, %Address{} = page) do
    heap[page] || exception(proc, "no page: #{inspect(page)}")
  end

  @spec get_return_stack(FarmProc.t()) :: [Pointer.t()]
  def get_return_stack(%FarmProc{rs: rs}), do: rs

  @spec get_kind(FarmProc.t(), Pointer.t()) :: atom
  def get_kind(%FarmProc{} = farm_proc, %Pointer{} = ptr) do
    get_cell_attr(farm_proc, ptr, Heap.kind())
  end

  @spec get_parent(FarmProc.t(), Pointer.t()) :: Address.t()
  def get_parent(%FarmProc{} = farm_proc, %Pointer{} = ptr) do
    get_cell_attr(farm_proc, ptr, Heap.parent())
  end

  @spec get_status(FarmProc.t()) :: status_enum()
  def get_status(%FarmProc{status: status}), do: status

  @spec set_status(FarmProc.t(), status_enum()) :: FarmProc.t()
  def set_status(%FarmProc{} = farm_proc, status) do
    %FarmProc{farm_proc | status: status}
  end

  @spec get_body_address(FarmProc.t(), Pointer.t()) :: Pointer.t()
  def get_body_address(
        %FarmProc{} = farm_proc,
        %Pointer{} = here_address
      ) do
    get_cell_attr_as_pointer(farm_proc, here_address, Heap.body())
  end

  @spec get_next_address(FarmProc.t(), Pointer.t()) :: Pointer.t()
  def get_next_address(
        %FarmProc{} = farm_proc,
        %Pointer{} = here_address
      ) do
    get_cell_attr_as_pointer(farm_proc, here_address, Heap.next())
  end

  @spec get_cell_attr(FarmProc.t(), Pointer.t(), atom) ::
          Address.t() | String.t() | number() | boolean() | atom()
  def get_cell_attr(
        %FarmProc{} = farm_proc,
        %Pointer{} = location,
        field
      ) do
    cell = get_cell_by_address(farm_proc, location)

    cell[field] ||
      exception(farm_proc, "no field called: #{field} at #{inspect(location)}")
  end

  @spec get_cell_attr_as_pointer(FarmProc.t(), Pointer.t(), atom) :: Pointer.t()
  def get_cell_attr_as_pointer(
        %FarmProc{} = farm_proc,
        %Pointer{} = location,
        field
      ) do
    %Address{} = data = get_cell_attr(farm_proc, location, field)
    Pointer.new(location.page_address, data)
  end

  @spec push_rs(FarmProc.t(), Pointer.t()) :: FarmProc.t()
  def push_rs(%FarmProc{} = farm_proc, %Pointer{} = ptr) do
    new_rs = [ptr | FarmProc.get_return_stack(farm_proc)]
    %FarmProc{farm_proc | rs: new_rs}
  end

  @spec pop_rs(FarmProc.t()) :: {Pointer.t(), FarmProc.t()}
  def pop_rs(%FarmProc{rs: rs} = farm_proc) do
    case rs do
      [hd | new_rs] ->
        {hd, %FarmProc{farm_proc | rs: new_rs}}

      [] ->
        {Pointer.null(FarmProc.get_zero_page(farm_proc)), farm_proc}
    end
  end

  @spec get_crash_reason(FarmProc.t()) :: String.t() | nil
  def get_crash_reason(%FarmProc{} = crashed),
    do: crashed.crash_reason

  @spec set_crash_reason(FarmProc.t(), String.t()) :: FarmProc.t()
  def set_crash_reason(%FarmProc{} = crashed, reason)
      when is_binary(reason) do
    %FarmProc{crashed | crash_reason: reason}
  end

  @spec is_null_address?(Address.t() | Pointer.t()) :: boolean()
  def is_null_address?(%Address{value: 0}), do: true
  def is_null_address?(%Address{}), do: false

  def is_null_address?(%Pointer{heap_address: %Address{value: 0}}),
    do: true

  def is_null_address?(%Pointer{}), do: false

  @spec get_cell_by_address(FarmProc.t(), Pointer.t()) :: map | no_return
  def get_cell_by_address(
        %FarmProc{} = farm_proc,
        %Pointer{page_address: page, heap_address: %Address{} = ha}
      ) do
    get_heap_by_page_index(farm_proc, page)[ha] ||
      exception(farm_proc, "bad address")
  end
end
