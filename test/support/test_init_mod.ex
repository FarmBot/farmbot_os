defmodule Farmbot.Test.TestInit do
  @moduledoc "Test init module."

  defmodule Worker do
    @moduledoc "Worker process for this init module"
    use GenServer
    
    @doc "Start a test worker"
    def start_link(args, opts \\ []) do
      GenServer.start_link(__MODULE__, args, opts)
    end

    @doc "Add a test function"
    def test_fun(server \\ __MODULE__, fun) do
      GenServer.call(server, {:test_fun, fun})
    end

    @doc "execute a test function"
    def exec(server \\ __MODULE__) do
      GenServer.call(server, :exec)
    end

    def init(_) do
      {:ok, nil}
    end

    def handle_call({:test_fun, fun}, _, _) do
      {:reply, :ok, fun}
    end

    def handle_call(:exec, _, fun) do
      # IO.puts "executing fun: #{inspect fun}"
      ret = fun.()
      {:reply, ret, nil}
    end
  end

  use Supervisor
  @behaviour Farmbot.System.Init

  @doc "initializes a fake module"
  def start_link(args, opts) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    children = [
      worker(Worker, [args, [name: Worker]])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
