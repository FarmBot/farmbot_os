defmodule Csvm.SysCallHandler do
  use GenServer
  @type ast :: Csvm.AST.t()
  @type return_value :: :ok | {:ok, any} | {:error, String.t()}
  @type sys_call_fun :: (ast -> return_value)
  @type sys_call :: pid

  @spec apply_sys_call_fun(sys_call_fun, ast) :: sys_call
  def apply_sys_call_fun(fun, ast) do
    {:ok, sys_call} = GenServer.start_link(__MODULE__, [fun, ast])
    sys_call
  end

  @spec get_status(sys_call) :: :ok | :complete
  def get_status(sys_call) do
    GenServer.call(sys_call, :get_status)
  end

  @spec get_results(sys_call) :: return_value | no_return()
  def get_results(sys_call) do
    case GenServer.call(sys_call, :get_results) do
      nil -> raise("no results")
      results -> results
    end
  end

  def init([fun, ast]) do
    pid = spawn_link(__MODULE__, :do_apply, [self(), fun, ast])
    {:ok, %{status: :ok, results: nil, pid: pid}}
  end

  def handle_info({_pid, info}, state) do
    {:noreply, %{state | results: info, status: :complete}}
  end

  def handle_call(:get_status, _from, state) do
    {:reply, state.status, state}
  end

  def handle_call(:get_results, _from, %{results: nil} = state) do
    {:stop, :normal, nil, state}
  end

  def handle_call(:get_results, _from, %{results: results} = state) do
    {:stop, :normal, results, state}
  end

  def do_apply(pid, fun, %Csvm.AST{} = ast)
      when is_pid(pid) and is_function(fun) do
    result =
      try do
        apply(fun, [ast])
      rescue
        ex ->
          {:error, Exception.message(ex)}
      end

    send(pid, {self(), result})
  end
end
