Application.ensure_all_started(:mimic)
Application.ensure_all_started(:farmbot)

defmodule Helpers do
  alias FarmbotOS.Asset.{Repo, Point}

  @wait_time 180
  @fake_jwt "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZ" <>
              "G1pbkBhZG1pbi5jb20iLCJpYXQiOjE1MDIxMjcxMTcsImp0a" <>
              "SI6IjlhZjY2NzJmLTY5NmEtNDhlMy04ODVkLWJiZjEyZDlhY" <>
              "ThjMiIsImlzcyI6Ii8vbG9jYWxob3N0OjMwMDAiLCJleHAiO" <>
              "jE1MDU1ODMxMTcsIm1xdHQiOiJsb2NhbGhvc3QiLCJvc191c" <>
              "GRhdGVfc2VydmVyIjoiaHR0cHM6Ly9hcGkuZ2l0aHViLmNvb" <>
              "S9yZXBvcy9mYXJtYm90L2Zhcm1ib3Rfb3MvcmVsZWFzZXMvb" <>
              "GF0ZXN0IiwiZndfdXBkYXRlX3NlcnZlciI6Imh0dHBzOi8vY" <>
              "XBpLmdpdGh1Yi5jb20vcmVwb3MvRmFybUJvdC9mYXJtYm90L" <>
              "WFyZHVpbm8tZmlybXdhcmUvcmVsZWFzZXMvbGF0ZXN0IiwiY" <>
              "m90IjoiZGV2aWNlXzE1In0.XidSeTKp01ngtkHzKD_zklMVr" <>
              "9ZUHX-U_VDlwCSmNA8ahOHxkwCtx8a3o_McBWvOYZN8RRzQV" <>
              "LlHJugHq1Vvw2KiUktK_1ABQ4-RuwxOyOBqqc11-6H_GbkM8" <>
              "dyzqRaWDnpTqHzkHGxanoWVTTgGx2i_MZLr8FPZ8prnRdwC1" <>
              "x9zZ6xY7BtMPtHW0ddvMtXU8ZVF4CWJwKSaM0Q2pTxI9GRqr" <>
              "p5Y8UjaKufif7bBPOUbkEHLNOiaux4MQr-OWAC8TrYMyFHzt" <>
              "eXTEVkqw7rved84ogw6EKBSFCVqwRA-NKWLpPMV_q7fRwiEG" <>
              "Wj7R-KZqRweALXuvCLF765E6-ENxA"

  @pub_key "-----BEGIN PUBLIC KEY-----\n" <>
             "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqi880lw9oeNp60qx5Oow\n" <>
             "9czLrvExJSGO6Yic7G+dvoqea9gLT3Xf0x4Iy4TmUfnFT2cJ1I79o/JS6WmfMVdr\n" <>
             "5Z0TaoVWYe9T01+kv6xWY+hENZTemAyCxSyPD7n6BgQYjXVoKSrdIuAoawtozQG+\n" <>
             "5KrS+KnRI70kVO2hgz1NXiEXuHF2Za4umCBONXBdpBSXVq1G5mpF6JURqu7oaTmE\n" <>
             "QNCmXfsJXE2srVwEshg80sb5rRtuoQAF7lAGZ3khV7DzKear5You9BWYNsl6etJZ\n" <>
             "lOSiNeGsDyUEocSIJ9Mn+y8jphJICbBADoKXO3ZkznnJRtLSE5cuh9KVL99LUWAk\n" <>
             "+wIDAQAB\n" <>
             "-----END PUBLIC KEY-----\n" <>
             ""

  @priv_key "-----BEGIN RSA PRIVATE KEY-----\n" <>
              "MIIEpAIBAAKCAQEAqi880lw9oeNp60qx5Oow9czLrvExJSGO6Yic7G+dvoqea9gL\n" <>
              "T3Xf0x4Iy4TmUfnFT2cJ1I79o/JS6WmfMVdr5Z0TaoVWYe9T01+kv6xWY+hENZTe\n" <>
              "mAyCxSyPD7n6BgQYjXVoKSrdIuAoawtozQG+5KrS+KnRI70kVO2hgz1NXiEXuHF2\n" <>
              "Za4umCBONXBdpBSXVq1G5mpF6JURqu7oaTmEQNCmXfsJXE2srVwEshg80sb5rRtu\n" <>
              "oQAF7lAGZ3khV7DzKear5You9BWYNsl6etJZlOSiNeGsDyUEocSIJ9Mn+y8jphJI\n" <>
              "CbBADoKXO3ZkznnJRtLSE5cuh9KVL99LUWAk+wIDAQABAoIBAFczFQsEUGAe0irJ\n" <>
              "fxU4GhYX9VWSKAhKhZuLcDyFhGIZTMsdS85PK3xVK1R8qDbgsATbWuIa0kOq6mjG\n" <>
              "wdbaYGKqdURjRbuwkVcA7r13ZFyUqj56JQPrhSXaiwMX29AxURNKUTCm0eAI0yzm\n" <>
              "D7DbcCBilu7qtEqHo5IQoG1Kf9X2cFYr7ikY8cx0E90RUTZ+P2RCuWskGEKxbUWJ\n" <>
              "epB2BwvxBAJrCSvt3DoXYWNkuxXo32SepqACyqyFPgWImvlz+5CACwrP8fXAhaut\n" <>
              "QbULN+4ltLnl7JQgKKMrGaKOGxvSwLFge9HyNg8ggdIkIjatxOJXLNNLyNgt6fNL\n" <>
              "FuICNSECgYEA4VRl4P3kFcAAIxdlDm0zm5bzegFTidr9QY9r1akzGIKGmT4uOAKX\n" <>
              "vWxQuR2R7LhYXeDW67BIkeYDZd+PW+eH6oVzb2W4MAggu6FeQgCa+uwnp6En13LE\n" <>
              "AX7NdH37h4SmbK4ssQQbb6S5oCuOzBKCVQCPlIRbEnk7MjluZBJfYnUCgYEAwVlP\n" <>
              "KBNL466T+8gKh5mQCXuV1bGKtYlbT/pnmNlz7gfXVPkj+UaBslOmDthEVbGvL4gY\n" <>
              "4T0vhP4VmIz8VqLw+jcCSezv0DjQVXYzZ8l+mNzHkacnnytM4VLQEYQnPB827Mo1\n" <>
              "FF2SjrfciQSyxxg+HOhHVUPovKvExsLtm8tzm68CgYEAl8o25x2hLFWuwfTcip9d\n" <>
              "iI5jbei+0brHqAZpagEU/onPCiQtFmYIuf3hUxJsXr7AKF1x6ktSV5ZO661x8UNC\n" <>
              "9+T2IjCvpwuSoVLPID8wJ6A2BmI1aJlTGH7HAJZtfpkJU2Txjj1qDgc1VISDKU2+\n" <>
              "pmw+TJnsj8FC805k4tzNjJECgYEAsDI+A2xKTStLqjgq+FWFwE6CReHsYPDSaLjt\n" <>
              "7YnErtcwcTw1fzW0fZjjDEYjR+CLoAoreh8zDcQqVAGu9xi3951nlYy5IgyUNj1o\n" <>
              "LR2fI5iWuXIVlmR0RCYefMfspUpg2DqRUoTPSQXekHLapLq/58H5N4eSMVVrFiKP\n" <>
              "O9mU+fsCgYALD10wthhtfYIMvcTaZ0rAF+X0chBvQzj1YaPbEf0YSocLysotcBjT\n" <>
              "M1m91bRjjR9vBhrg5RDOz3RCIlJ3ipkaE+cfxyUs0+AXwIXIPs2hVJNFRT8d7Z4e\n" <>
              "boWHfxAwHFqoEYzskZCdPArDzshm2bFetCh6Cpw7HsWdtS18X8M8+g==\n" <>
              "-----END RSA PRIVATE KEY-----\n" <>
              ""

  def priv_key(), do: @priv_key
  def pub_key(), do: @pub_key
  def fake_jwt(), do: @fake_jwt

  defmacro fake_jwt_object() do
    quote do
      FarmbotOS.JWT.decode!(unquote(@fake_jwt))
    end
  end

  defmacro use_fake_jwt() do
    quote do
      cb = fn :string, "authorization", "token" ->
        Helpers.fake_jwt()
      end

      expect(FarmbotOS.Config, :get_config_value, 1, cb)
    end
  end

  defmacro expect_log(msg) do
    quote do
      expect(FarmbotOS.LogExecutor, :execute, 1, fn log ->
        assert log.message =~ unquote(msg)
      end)
    end
  end

  defmacro expect_logs(strings) do
    log_count = Enum.count(strings)

    quote do
      expect(FarmbotOS.LogExecutor, :execute, unquote(log_count), fn log ->
        assert Enum.member?(unquote(strings), log.message)
      end)
    end
  end

  # Base case: We have a pid
  def wait_for(pid) when is_pid(pid), do: check_on_mbox(pid)
  # Failure case: We failed to find a pid for a module.
  def wait_for(nil), do: raise("Attempted to wait on bad module/pid")
  # Edge case: We have a module and need to try finding its pid.
  def wait_for(mod), do: wait_for(Process.whereis(mod))

  # Enter recursive loop
  defp check_on_mbox(pid) do
    Process.sleep(@wait_time)
    wait(pid, Process.info(pid, :message_queue_len))
  end

  # Exit recursive loop (mbox is clear)
  defp wait(_, {:message_queue_len, 0}), do: Process.sleep(@wait_time * 3)
  # Exit recursive loop (pid is dead)
  defp wait(_, nil), do: Process.sleep(@wait_time * 3)

  # Continue recursive loop
  defp wait(pid, {:message_queue_len, _n}), do: check_on_mbox(pid)

  def delete_all_points(), do: Repo.delete_all(Point)

  def create_point(%{id: id} = params) do
    %Point{
      id: id,
      name: "point #{id}",
      meta: %{},
      plant_stage: "planted",
      created_at: ~U[2222-12-10 02:22:22.222222Z],
      pointer_type: "Plant",
      pullout_direction: 2,
      radius: 10.0,
      tool_id: nil,
      discarded_at: nil,
      gantry_mounted: false,
      x: 0.0,
      y: 0.0,
      z: 0.0
    }
    |> Map.merge(params)
    |> Point.changeset()
    |> Repo.insert!()
  end
end

# Use this to stub out calls to `state.reset.reset()` in firmware.
defmodule StubReset do
  def reset(), do: :ok
end

defmodule NoOp do
  use GenServer

  def new(opts \\ []) do
    {:ok, pid} = start_link(opts)
    pid
  end

  def stop(pid) do
    _ = Process.unlink(pid)
    :ok = GenServer.stop(pid, :normal, 3_000)
  end

  def last_message(pid) do
    :sys.get_state(pid)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    {:ok, :no_message_yet}
  end

  def handle_info(next_message, _last_message) do
    {:noreply, next_message}
  end
end

defmodule SimpleCounter do
  def new(starting_value \\ 0) do
    Agent.start_link(fn -> starting_value end)
  end

  def get_count(pid) do
    Agent.get(pid, fn count -> count end)
  end

  def incr(pid, by \\ 1) do
    Agent.update(pid, fn count -> count + by end)
    pid
  end

  # Increment the counter by one and get the current count.
  def bump(pid, by \\ 1) do
    pid |> incr(by) |> get_count()
  end
end

defmodule Farmbot.TestSupport.AssetFixtures do
  alias FarmbotOS.Asset.{
    Device,
    FarmEvent,
    Regimen,
    RegimenInstance,
    Repo,
    Sequence
  }

  def regimen_instance(regimen_params, farm_event_params, params \\ %{}) do
    regimen = regimen(regimen_params)
    farm_event = regimen_event(regimen, farm_event_params)
    params = Map.merge(%{id: :rand.uniform(10000), monitor: false}, params)

    RegimenInstance.changeset(%RegimenInstance{}, params)
    |> Ecto.Changeset.put_assoc(:regimen, regimen)
    |> Ecto.Changeset.put_assoc(:farm_event, farm_event)
    |> Repo.insert!()
  end

  def sequence(params \\ %{}) do
    default = %{
      id: :rand.uniform(10000),
      monitor: false,
      kind: "sequence",
      args: %{locals: %{kind: "scope_declaration", args: %{}}},
      body: []
    }

    Sequence
    |> struct()
    |> Sequence.changeset(Map.merge(default, params))
    |> Repo.insert!()
  end

  def regimen(params \\ %{}) do
    default = %{id: :rand.uniform(10000), monitor: false, regimen_items: []}

    Regimen
    |> struct()
    |> Regimen.changeset(Map.merge(default, params))
    |> Repo.insert!()
  end

  def regimen_event(regimen, params \\ %{}) do
    now = DateTime.utc_now()

    params =
      Map.merge(
        %{
          id: :rand.uniform(1_000_000),
          monitor: false,
          executable_type: "Regimen",
          executable_id: regimen.id,
          start_time: now,
          end_time: now,
          repeat: 0,
          time_unit: "never"
        },
        params
      )

    FarmEvent
    |> struct()
    |> FarmEvent.changeset(params)
    |> Repo.insert!()
  end

  @doc """
  Instantiates, but does not create, a %Device{}
  """
  def device_init(params \\ %{}) do
    defaults = %{id: :rand.uniform(1_000_000), monitor: false}
    params = Map.merge(defaults, params)

    Device
    |> struct()
    |> Device.changeset(params)
    |> Ecto.Changeset.apply_changes()
  end
end

timeout = System.get_env("EXUNIT_TIMEOUT") || "5000"
System.put_env("LOG_SILENCE", "true")

ExUnit.configure(
  max_cases: 1,
  assert_receive_timeout: String.to_integer(timeout)
)

[
  Circuits.UART,
  Ecto.Changeset,
  ExTTY,
  FarmbotOS.API,
  FarmbotOS.API.Reconciler,
  FarmbotOS.API.SyncGroup,
  FarmbotOS.APIFetcher,
  FarmbotOS.Asset,
  FarmbotOS.Asset.Command,
  FarmbotOS.Asset.Device,
  FarmbotOS.Asset.FbosConfig,
  FarmbotOS.Asset.FirmwareConfig,
  FarmbotOS.Asset.Private,
  FarmbotOS.Asset.Repo,
  FarmbotOS.Bootstrap.Authorization,
  FarmbotOS.Bootstrap.DropPasswordSupport,
  FarmbotOS.BotState,
  FarmbotOS.BotStateNG,
  FarmbotOS.Celery,
  FarmbotOS.Celery.AST.Factory,
  FarmbotOS.Celery.Compiler.Lua,
  FarmbotOS.Celery.Scheduler,
  FarmbotOS.Celery.SpecialValue,
  FarmbotOS.Celery.SysCallGlue,
  FarmbotOS.Celery.SysCallGlue.Stubs,
  FarmbotOS.Config,
  FarmbotOS.Configurator.ConfigDataLayer,
  FarmbotOS.Configurator.DetsTelemetryLayer,
  FarmbotOS.Configurator.FakeNetworkLayer,
  FarmbotOS.EagerLoader.Supervisor,
  FarmbotOS.FarmwareRuntime,
  FarmbotOS.FarmwareRuntime.RunCommand,
  FarmbotOS.Firmware.Avrdude,
  FarmbotOS.Firmware.Command,
  FarmbotOS.Firmware.ConfigUploader,
  FarmbotOS.Firmware.Flash,
  FarmbotOS.Firmware.FlashUtils,
  FarmbotOS.Firmware.Resetter,
  FarmbotOS.Firmware.TxBuffer,
  FarmbotOS.Firmware.UARTCore,
  FarmbotOS.Firmware.UARTCoreSupport,
  FarmbotOS.Firmware.UARTDetector,
  FarmbotOS.FirmwareEstopTimer,
  FarmbotOS.HTTP,
  FarmbotOS.Leds,
  FarmbotOS.LogExecutor,
  FarmbotOS.Logger,
  FarmbotOS.Lua,
  FarmbotOS.Lua.DataManipulation,
  FarmbotOS.Lua.Firmware,
  FarmbotOS.Lua.Info,
  FarmbotOS.MQTT,
  FarmbotOS.MQTT.LogHandlerSupport,
  FarmbotOS.MQTT.Support,
  FarmbotOS.MQTT.SyncHandlerSupport,
  FarmbotOS.MQTT.TerminalHandlerSupport,
  FarmbotOS.MQTT.TopicSupervisor,
  FarmbotOS.SysCalls,
  FarmbotOS.SysCalls.ChangeOwnership,
  FarmbotOS.SysCalls.ChangeOwnership.Support,
  FarmbotOS.SysCalls.Farmware,
  FarmbotOS.SysCalls.Movement,
  FarmbotOS.SysCalls.ResourceUpdate,
  FarmbotOS.System,
  FarmbotOS.Time,
  FarmbotOS.UpdateSupport,
  FarmbotTelemetry,
  File,
  MuonTrap,
  System,
  IO,
  Timex,
  Tortoise311
]
|> Enum.map(&Mimic.copy/1)

ExUnit.start()
