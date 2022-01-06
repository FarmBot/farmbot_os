defmodule FarmbotOS.BotStateNG do
  @moduledoc """
  The data strucutre behind the bot state tree (not the living process).
  Also has some helpers for batching changes.
  """

  alias FarmbotOS.{
    BotStateNG,
    BotStateNG.McuParams,
    BotStateNG.LocationData,
    BotStateNG.InformationalSettings,
    BotStateNG.Configuration
  }

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  @legacy_info %{
    farmwares: %{
      "Measure Soil Height": %{
        config: %{
          "0": %{
            label:
              "Measured distance from camera to soil in millimeters (required input for calibration)",
            name: "measured_distance",
            value: 0
          },
          "1": %{
            label: "Disparity search depth",
            name: "disparity_search_depth",
            value: 1
          },
          "10": %{
            label: "Calibration maximum",
            name: "calibration_maximum",
            value: 0
          },
          "2": %{
            label: "Disparity block size",
            name: "disparity_block_size",
            value: 15
          },
          "3": %{
            label: "Image output",
            name: "verbose",
            value: 2
          },
          "4": %{
            label: "Log verbosity",
            name: "log_verbosity",
            value: 1
          },
          "5": %{
            label: "Calibration factor result",
            name: "calibration_factor",
            value: 0
          },
          "6": %{
            label: "Calibration offset result",
            name: "calibration_disparity_offset",
            value: 0
          },
          "7": %{
            label: "Image width during calibration",
            name: "calibration_image_width",
            value: 0
          },
          "8": %{
            label: "Image height during calibration",
            name: "calibration_image_height",
            value: 0
          },
          "9": %{
            label: "Z-axis position during calibration",
            name: "calibration_measured_at_z",
            value: 0
          }
        },
        description: "Measure soil z height at the current position.",
        farmware_manifest_version: "2.0.0",
        package: "Measure Soil Height",
        package_version: "1.4.6"
      },
      "camera-calibration": %{
        config: %{},
        description: "Calibrate the camera for use in plant-detection.",
        farmware_manifest_version: "2.0.0",
        package: "camera-calibration",
        package_version: "0.0.2"
      },
      "historical-camera-calibration": %{
        config: %{},
        description:
          "Calibrate the camera with historical image for use in plant-detection.",
        farmware_manifest_version: "2.0.0",
        package: "historical-camera-calibration",
        package_version: "0.0.2"
      },
      "historical-plant-detection": %{
        config: %{},
        description:
          "Detect and mark plants in historical image. Prerequisite: camera-calibration",
        farmware_manifest_version: "2.0.0",
        package: "historical-plant-detection",
        package_version: "0.0.2"
      },
      "plant-detection": %{
        config: %{},
        description: "Detect and mark plants. Prerequisite: camera-calibration",
        farmware_manifest_version: "2.0.0",
        package: "plant-detection",
        package_version: "0.0.20"
      },
      "take-photo": %{
        config: %{},
        description: "Take a photo using a USB or Raspberry Pi camera.",
        farmware_manifest_version: "2.0.0",
        package: "take-photo",
        package_version: "1.0.19"
      }
    }
  }

  embedded_schema do
    embeds_one(:mcu_params, McuParams, on_replace: :update)
    embeds_one(:location_data, LocationData, on_replace: :update)

    embeds_one(:informational_settings, InformationalSettings,
      on_replace: :update
    )

    embeds_one(:configuration, Configuration, on_replace: :update)
    field(:user_env, :map, default: %{})
    field(:process_info, :map, default: @legacy_info)
    field(:pins, :map, default: %{})
    field(:jobs, :map, default: %{})
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
      informational_settings:
        InformationalSettings.view(bot_state.informational_settings),
      configuration: Configuration.view(bot_state.configuration),
      process_info: Map.merge(@legacy_info, bot_state.process_info),
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
    t = FarmbotOS.Time.system_time_ms() / 1000
    progress2 = Map.put(progress, :updated_at, t)

    new_jobs =
      cs
      |> get_field(:jobs)
      |> Map.put(name, progress2)

    put_change(cs, :jobs, new_jobs)
  end
end
