defmodule Farmbot.CeleryScript.RunTime.Instruction do
  @moduledoc """
  Macros for quickly defining executionally similar instructions.
  """

  alias Farmbot.CeleryScript.RunTime.{FarmProc, SysCallHandler}
  alias Farmbot.CeleryScript.AST
  import SysCallHandler, only: [apply_sys_call_fun: 2]

  @doc """
  A simple IO based instruction that doesn't do any variable resolution or
  special transformation before passing to the SysCallHandler.
  """
  defmacro simple_io_instruction(instruction_name) do
    quote do
      @spec unquote(instruction_name)(FarmProc.t()) :: FarmProc.t()
      def unquote(instruction_name)(%FarmProc{} = farm_proc) do
        case farm_proc.io_result do
          nil ->
            pc = get_pc_ptr(farm_proc)

            heap = get_heap_by_page_index(farm_proc, pc.page_address)

            data = AST.unslice(heap, pc.heap_address)
            latch = apply_sys_call_fun(farm_proc.sys_call_fun, data)

            farm_proc
            |> set_status(:waiting)
            |> set_io_latch(latch)

          :ok ->
            farm_proc
            |> clear_io_result()
            |> next_or_return()

          {:error, reason} ->
            crash(farm_proc, reason)

          other ->
            exception(farm_proc, "Bad return value: #{inspect(other)}")
        end
      end
    end
  end
end
