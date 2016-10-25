defmodule NesBotControl do
  use GenServer
  @moduledoc """
    Use a new controller to control the bots servos.
  """

  def init(_) do
    {:ok, pid} = NesController.start_link(self())
    {:ok, {:none, pid}}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # if there is already something happening, dont allow other stuff
  def handle_info(button, {last_button, pid})
  when button == last_button do
    {:noreply, {button, pid}}
  end

  def handle_info(:up, {:none, pid}) do
    Command.move_relative({:y, 100, 100})
    {:noreply, {:up, pid}}
  end

  def handle_info(:down, {:none, pid}) do
    Command.move_relative({:y, 100, -100})
    {:noreply, {:down, pid}}
  end

  def handle_info(:left, {:none, pid}) do
    Command.move_relative({:x, 100, -100})
    {:noreply, {:left, pid}}
  end

  def handle_info(:right, {:none, pid} ) do
    Command.move_relative({:x, 100, 100})
    {:noreply, {:right, pid}}
  end

  def handle_info(:a, {:none, pid}) do
    Command.move_relative({:z, 100, 100})
    {:noreply, {:a, pid}}
  end

  def handle_info(:b, {:none, pid}) do
    Command.move_relative({:z, 100, -100})
    {:noreply, {:b, pid}}
  end

  def handle_info(:select, {:none, pid}) do
    Command.home_all(100)
    {:noreply, {:select, pid}}
  end

  def handle_info(:start, {:none, pid}) do
    Command.home_all(100)
    {:noreply, {:start, pid}}
  end

  def handle_info(:done, {_old_button, pid}) do
    Process.sleep(200) # wait for bot position to be updated
    {:noreply, {:none, pid}}
  end

  def handle_info(button, {last_button, pid}) do
    {:noreply, {last_button, pid}}
  end
end
