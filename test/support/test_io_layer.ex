defmodule Farmbot.TestSupport.CeleryScript.TestIOLayer do
  @behaviour Farmbot.Core.CeleryScript.IOLayer
  def calibrate(args, body), do: dispatch(:calibrate, args, body)
  def change_ownership(args, body), do: dispatch(:change_ownership, args, body)
  def check_updates(args, body), do: dispatch(:check_updates, args, body)
  def config_update(args, body), do: dispatch(:config_update, args, body)
  def dump_info(args, body), do: dispatch(:dump_info, args, body)
  def emergency_lock(args, body), do: dispatch(:emergency_lock, args, body)
  def emergency_unlock(args, body), do: dispatch(:emergency_unlock, args, body)
  def execute(args, body), do: dispatch(:execute, args, body)
  def execute_script(args, body), do: dispatch(:execute_script, args, body)
  def factory_reset(args, body), do: dispatch(:factory_reset, args, body)
  def find_home(args, body), do: dispatch(:find_home, args, body)
  def home(args, body), do: dispatch(:home, args, body)
  def move_absolute(args, body), do: dispatch(:move_absolute, args, body)
  def move_relative(args, body), do: dispatch(:move_relative, args, body)
  def power_off(args, body), do: dispatch(:power_off, args, body)
  def read_pin(args, body), do: dispatch(:read_pin, args, body)
  def read_status(args, body), do: dispatch(:read_status, args, body)
  def reboot(args, body), do: dispatch(:reboot, args, body)
  def send_message(args, body), do: dispatch(:send_message, args, body)
  def set_servo_angle(args, body), do: dispatch(:set_servo_angle, args, body)
  def set_user_env(args, body), do: dispatch(:set_user_env, args, body)
  def sync(args, body), do: dispatch(:sync, args, body)
  def take_photo(args, body), do: dispatch(:take_photo, args, body)
  def toggle_pin(args, body), do: dispatch(:toggle_pin, args, body)
  def wait(args, body), do: dispatch(:wait, args, body)
  def write_pin(args, body), do: dispatch(:write_pin, args, body)
  def zero(args, body), do: dispatch(:zero, args, body)
  def _if(args, body), do: dispatch(:_if, args, body)
  def debug(args, body), do: dispatch(:debug, args, body)

  defmodule Tracker do
    use GenServer

    def dispatch(msg) do
      GenServer.cast(__MODULE__, {:dispatch, msg})
    end

    def subscribe do
      GenServer.cast(__MODULE__, {:subscribe, self()})
    end

    def start_link do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init(subs) do
      {:ok, subs}
    end

    def handle_cast({:dispatch, msg}, subs) do
      for pid <- subs do
        Process.alive?(pid) && send(pid, msg)
      end

      {:noreply, subs}
    end

    def handle_cast({:subscribe, pid}, subs), do: {:noreply, [pid | subs]}
  end

  def dispatch(kind, args, body) do
    Tracker.start_link()
    ast = %{kind: kind, args: args, body: body}
    Tracker.dispatch(ast)
    {:error, to_string(kind)}
  end

  def subscribe do
    Tracker.start_link()
    Tracker.subscribe()
  end

  def debug_ast(params \\ %{}) do
    %{
      kind: :debug,
      args: %{label: uuid()},
      body: []
    }
    |> Map.merge(params)
  end

  def debug_fun(_), do: :ok

  def uuid, do: Ecto.UUID.generate()
end
