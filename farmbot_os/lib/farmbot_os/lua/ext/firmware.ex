defmodule FarmbotOS.Lua.Ext.Firmware do
  @moduledoc """
  Lua extensions for interacting with the Firmware
  """
  @axis ["x", "y", "z"]

  alias FarmbotCeleryScript.SysCalls
  alias FarmbotCore.Firmware.Command

  def calibrate([axis], lua) when axis in @axis do
    case SysCalls.calibrate(axis) do
      :ok ->
        {[true], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def emergency_lock(_, lua) do
    case SysCalls.emergency_lock() do
      :ok ->
        {[true], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def emergency_unlock(_, lua) do
    case SysCalls.emergency_unlock() do
      :ok ->
        {[true], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def find_home(["all"], lua),
    do: do_find_home(@axis, lua, &SysCalls.find_home/1)

  def find_home([axis], lua),
    do: do_find_home([axis], lua, &SysCalls.find_home/1)

  def find_home([], lua), do: find_home(["all"], lua)

  def go_to_home([axis, speed], lua) when axis in @axis do
    defaults = %{
      "x" => SysCalls.get_current_x(),
      "y" => SysCalls.get_current_y(),
      "z" => SysCalls.get_current_z()
    }

    mask = %{axis => 0}
    p = Map.merge(defaults, mask)
    args = Map.values(p) ++ [speed]

    case apply(SysCalls, :move_absolute, args) do
      :ok -> {[true], lua}
      {:error, reason} -> {[nil, reason], lua}
    end
  end

  def go_to_home(["all", speed], lua) do
    case SysCalls.move_absolute(0, 0, 0, speed) do
      :ok -> {[true], lua}
      {:error, reason} -> {[nil, reason], lua}
    end
  end

  def go_to_home([axis], lua) do
    go_to_home([axis, 100], lua)
  end

  def go_to_home(_, lua) do
    go_to_home(["all", 100], lua)
  end

  @doc "Moves in a straight line to a location"
  def move_absolute([x, y, z], lua)
      when is_number(x) and is_number(y) and is_number(z) do
    move_absolute([x, y, z, 100], lua)
  end

  def move_absolute([x, y, z, speed], lua)
      when is_number(x) and is_number(y) and is_number(z) and is_number(speed) do
    case SysCalls.move_absolute(x, y, z, speed) do
      :ok ->
        {[true], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def move_absolute([table], lua) when is_list(table) do
    move_absolute([table, 100], lua)
  end

  def move_absolute([table, speed], lua)
      when is_list(table) and is_number(speed) do
    axis_finder = fn
      axis, {axis, nil} -> apply(SysCalls, :"get_current_#{axis}", [])
      axis, {axis, value} -> value
      _, {_axis, _value} -> false
    end

    x = Enum.find_value(table, &axis_finder.("x", &1))
    y = Enum.find_value(table, &axis_finder.("y", &1))
    z = Enum.find_value(table, &axis_finder.("z", &1))
    move_absolute([x, y, z, speed], lua)
  end

  @doc """
  Returns a table containing position data

  ## Example

      print("x", get_position().x);
      print("y", get_position()["y"]);
      position = get_position();
      print("z", position.z);
  """
  def get_position(["x"], lua) do
    case SysCalls.get_current_x() do
      x when is_number(x) ->
        {[x], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def get_position(["y"], lua) do
    case SysCalls.get_current_y() do
      y when is_number(y) ->
        {[y], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def get_position(["z"], lua) do
    case SysCalls.get_current_z() do
      z when is_number(z) ->
        {[z], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def get_position(_args, lua) do
    with x when is_number(x) <- SysCalls.get_current_x(),
         y when is_number(y) <- SysCalls.get_current_y(),
         z when is_number(z) <- SysCalls.get_current_z() do
      {[[{"x", x}, {"y", y}, {"z", z}]], lua}
    else
      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def check_position([vec3, tolerance], lua) do
    axis_finder = fn
      axis, {axis, nil} -> apply(SysCalls, :"get_current_#{axis}", [])
      axis, {axis, value} -> value
      _, {_axis, _value} -> false
    end

    x = Enum.find_value(vec3, &axis_finder.("x", &1))
    y = Enum.find_value(vec3, &axis_finder.("y", &1))
    z = Enum.find_value(vec3, &axis_finder.("z", &1))

    with current_x when is_number(x) <- SysCalls.get_current_x(),
         current_y when is_number(y) <- SysCalls.get_current_y(),
         current_z when is_number(z) <- SysCalls.get_current_z() do
      x_check = x >= current_x - tolerance and x <= current_x + tolerance
      y_check = y >= current_y - tolerance and y <= current_y + tolerance
      z_check = z >= current_z - tolerance and z <= current_z + tolerance
      {[x_check && y_check && z_check], lua}
    else
      {:error, reason} -> {[nil, reason], lua}
    end
  end

  def coordinate([x, y, z], lua)
      when is_number(x) and is_number(y) and is_number(z) do
    {[[{"x", x}, {"y", y}, {"z", z}]], lua}
  end

  def read_pin([pin, mode], lua) do
    m =
      case mode do
        "analog" -> 1
        _ -> 0
      end

    case Command.read_pin(pin, m) do
      {:ok, v} -> {[v], lua}
      {:error, reason} -> {[nil, reason], lua}
    end
  end

  def read_pin([pin], lua), do: read_pin([pin, "digital"], lua)

  @options ["input", "input_pullup", "output"]

  def set_pin_io_mode([pin, mode], lua) when mode in @options do
    result = SysCalls.set_pin_io_mode(pin, mode)

    case result do
      :ok ->
        {[true, nil], lua}

      other ->
        {[false, inspect(other)], lua}
    end
  end

  def set_pin_io_mode([_pin, _mode], lua) do
    error = "Expected pin mode to be one of: #{inspect(@options)}"
    {[false, error], lua}
  end

  defp do_find_home(axes, lua, callback) do
    axes
    |> Enum.map(callback)
    |> Enum.reverse()
    |> Enum.map(fn result ->
      case result do
        {:error, reason} -> reason
        _ -> nil
      end
    end)
    |> Enum.uniq()
    |> case do
      [nil] -> {[true], lua}
      reasons -> {[nil, Enum.join(reasons, " ")], lua}
    end
  end
end
