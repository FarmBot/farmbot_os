defmodule FarmbotCore.BotStateNG do
  alias FarmbotCore.{
    BotStateNG,
    BotStateNG.McuParams,
    BotStateNG.LocationData,
    BotStateNG.InformationalSettings,
    BotStateNG.Configuration
  }

  alias FarmbotCore.Asset.Private.Enigma

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    embeds_one(:mcu_params, McuParams, on_replace: :update)
    embeds_one(:location_data, LocationData, on_replace: :update)
    embeds_one(:informational_settings, InformationalSettings, on_replace: :update)
    embeds_one(:configuration, Configuration, on_replace: :update)
    field(:user_env, {:map, {:string, :any}}, default: %{})
    field(:process_info, {:map, {:string, :any}}, default: %{farmwares: %{}})
    field(:pins, {:map, {:integer, :map}}, default: %{})
    field(:jobs, {:map, {:string, :map}}, default: %{})
    field(:enigmas, {:map, {:string, :map}}, default: %{})
  end

  def new do
    %BotStateNG{}
    |> changeset(%{})
    |> put_embed(:mcu_params, McuParams.new())
    |> put_embed(:location_data, LocationData.new())
    |> put_embed(:informational_settings, InformationalSettings.new())
    |> put_embed(:configuration, Configuration.new())
    |> apply_changes()
  end

  def changeset(bot_state, params \\ %{}) do
    bot_state
    |> cast(params, [:user_env, :pins, :jobs, :process_info])
    |> cast_embed(:mcu_params, [])
    |> cast_embed(:location_data, [])
    |> cast_embed(:informational_settings, [])
    |> cast_embed(:configuration, [])
  end

  def view(bot_state) do
    %{
      mcu_params: McuParams.view(bot_state.mcu_params),
      location_data: LocationData.view(bot_state.location_data),
      informational_settings: InformationalSettings.view(bot_state.informational_settings),
      configuration: Configuration.view(bot_state.configuration),
      process_info: bot_state.process_info,
      user_env: bot_state.user_env,
      pins: bot_state.pins,
      jobs: bot_state.jobs
    }
  end

  @doc "Add or update a pin to state.pins."
  def add_or_update_pin(state, number, mode, value) do
    cs = changeset(state, %{})

    new_pins =
      cs
      |> get_field(:pins)
      |> Map.put(number, %{mode: mode, value: value})

    put_change(cs, :pins, new_pins)
  end

  @doc "Add or update a farmware to state.farmwares"
  def add_or_update_farmware(state, name, %{} = manifest) do
    cs = changeset(state, %{})

    new_farmwares =
      cs
      |> get_field(:process_info)
      |> Map.get(:farmwares)
    put_change(cs, :process_info, %{farmwares: new_farmwares})
  end

  @doc "Sets an env var on the state.user_env"
  def set_user_env(state, key, value) do
    cs = changeset(state, %{})

    new_user_env =
      cs
      |> get_field(:user_env)
      |> Map.put(key, value)

    put_change(cs, :user_env, new_user_env)
  end

  @doc "Sets a progress objecto on state.jobs"
  def set_job_progress(state, name, progress) do
    cs = changeset(state, %{})

    new_jobs =
      cs
      |> get_field(:jobs)
      |> Map.put(name, progress)

    put_change(cs, :jobs, new_jobs)
  end

  @doc "Adds an enigma object to state.enigmas"
  def add_enigma(state, %Enigma{local_id: uuid} = enigma) do
    cs = changeset(state, %{})

    new_enigmas =
      cs
      |> get_field(:enigmas)
      |> Map.put(uuid, Enigma.render(enigma))

    put_change(cs, :enigmas, new_enigmas)
  end

  @doc "clears an enigma object on state.enigmas"
  def clear_enigma(state, %Enigma{local_id: uuid}) do
    cs = changeset(state, %{})

    new_enigmas =
      cs
      |> get_field(:enigmas)
      |> Map.delete(uuid)

    put_change(cs, :enigmas, new_enigmas)
  end
end
