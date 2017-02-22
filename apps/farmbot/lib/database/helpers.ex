alias Farmbot.Sync.Database.Device
alias Farmbot.Sync.Database.FarmEvent
alias Farmbot.Sync.Database.Peripheral
alias Farmbot.Sync.Database.Point
alias Farmbot.Sync.Database.RegimenItem
alias Farmbot.Sync.Database.Regimen
alias Farmbot.Sync.Database.Sequence
alias Farmbot.Sync.Database.ToolBay
alias Farmbot.Sync.Database.ToolSlot
alias Farmbot.Sync.Database.Tool
alias Farmbot.Sync.Database.User

defmodule Farmbot.Sync.Helpers do
  @moduledoc """
    Things that should be macros but Amnesia does some weird stuff.
  """
  use Amnesia
  use Device
  use FarmEvent
  use Peripheral
  use Point
  # use RegimenItem
  use Regimen
  use Sequence
  use ToolBay
  use ToolSlot
  use Tool
  use User

  @doc """
    Gets a device by id
  """
  @lint false
  def get_device(find_id) do
    Amnesia.transaction do
      Device.where id == find_id
    end
    |> parse_selection
  end
  _ = @lint # HACK(Connor) fix credo compiler warning

  @doc """
    Gets a farm event by id
  """
  @lint false
  def get_farm_event(find_id) do
    Amnesia.transaction do
      FarmEvent.where id == find_id
    end
    |> parse_selection
  end

  @doc """
    Gets a peripheral by id
  """
  @lint false
  def get_peripheral(find_id) do
    Amnesia.transaction do
      Peripheral.where id == find_id
    end
    |> parse_selection
  end

  @doc """
    Gets a point by id
  """
  @lint false
  def get_point(find_id) do
    Amnesia.transaction do
      Point.where id == find_id
    end
    |> parse_selection
  end

  # @doc """
  #   Gets a regimen_item by id
  # """
  # @lint false
  # def get_regimen_item(find_id) do
  #   Amnesia.transaction do
  #     RegimenItem.where id == find_id
  #   end
  #   |> parse_selection
  # end

  @doc """
    Gets a regimen by id
  """
  @lint false
  def get_regimen(find_id) do
    Amnesia.transaction do
      Regimen.where id == find_id
    end
    |> parse_selection
  end

  @doc """
    Gets a sequence by id
  """
  @lint false
  def get_sequence(find_id) do
    Amnesia.transaction do
      Sequence.where id == find_id
    end
    |> parse_selection
  end

  @doc """
    Gets a tool_bay by id
  """
  @lint false
  def get_tool_bay(find_id) do
    Amnesia.transaction do
      ToolBay.where id == find_id
    end
    |> parse_selection
  end

  @doc """
    Gets a tool_slot by id
  """
  @lint false
  def get_tool_slot(find_id) do
    Amnesia.transaction do
      ToolSlot.where id == find_id
    end
    |> parse_selection
  end

  @doc """
    Gets a tool by id
  """
  @lint false
  def get_tool(find_id) do
    Amnesia.transaction do
      Tool.where id == find_id
    end
    |> parse_selection
  end

  @doc """
    Gets a user by id
  """
  @lint false
  def get_user(find_id) do
    Amnesia.transaction do
      User.where id == find_id
    end
    |> parse_selection
  end

  @doc """
    Gets the current Device Name.
  """
  @lint false
  def get_device_name do
    Amnesia.transaction do
      # there is only ever at most one device..
      Device.first
      || %Device{id: -1, name: "Farmbot", planting_area_id: nil, webcam_url: nil}
    end
    |> Map.get(:name)
  end

  @lint false # Amnesia.Selection doesnt need to be aliased Credo!
  defp parse_selection(nil), do: nil
  defp parse_selection(selection) do
    f = Amnesia.Selection.values(selection)
    if Enum.count(f) == 1 do
      List.first(f)
    else
      f
    end
  end
end
