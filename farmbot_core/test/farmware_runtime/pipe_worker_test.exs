defmodule Farmbot.FarmwareRuntime.PipeWorkerTest do
  use ExUnit.Case, async: false
  alias Farmbot.FarmwareRuntime.PipeWorker

  test "reads data from pipe" do
    pipe_name = random_pipe()
    {:ok, pipe_worker} = PipeWorker.start_link(pipe_name)
    ref = PipeWorker.read(pipe_worker, 11)
    {_, 0} = System.cmd("bash", ["-c", "echo -e 'hello world' > #{pipe_name}"])
    assert_receive {PipeWorker, ^ref, {:ok, "hello world"}}
  end

  test "writes data to a pipe" do
    pipe_name = random_pipe()
    {:ok, pipe_worker} = PipeWorker.start_link(pipe_name)

    ref = PipeWorker.read(pipe_worker, 11)
    PipeWorker.write(pipe_worker, "hello world")
    assert_receive {PipeWorker, ^ref, {:ok, "hello world"}}
  end

  test "cleanup pipes on exit" do
    pipe_name = random_pipe()
    {:ok, pipe_worker} = PipeWorker.start_link(pipe_name)
    assert File.exists?(pipe_name)
    _ = Process.flag(:trap_exit, true)
    :ok = PipeWorker.close(pipe_worker)
    assert_receive {:EXIT, ^pipe_worker, :normal}
    refute File.exists?(pipe_name)
  end

  defp random_pipe do
    pipe_name = Ecto.UUID.generate() <> ".pipe"
    Path.join([System.tmp_dir!(), pipe_name])
  end
end
