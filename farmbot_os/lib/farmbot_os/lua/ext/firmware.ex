defmodule FarmbotOS.Lua.Ext.Firmware do
  @moduledoc """
  Lua extensions for interacting with the Firmware
  """
  @axis ["x", "y", "z"]

  alias FarmbotCeleryScript.SysCalls

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

  def find_home([axis], lua) when axis in @axis do
    case SysCalls.find_home(axis) do
      :ok ->
        {[true], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def home([axis, speed], lua) when axis in @axis do
    IO.inspect({axis, speed}, label: "=== YOWZA")

    case SysCalls.home(axis, speed) do
      :ok -> {[true], lua}
      {:error, reason} -> {[nil, reason], lua}
    end
  end

  def home([axis], lua) when axis in @axis do
    home([axis, 100], lua)
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

  def get_pin(args, lua) do
    get_pins(args, lua)
  end

  @doc """
  Returns a table with pins data

  ## Example

    print("pin9", get_pins()["9"]);

    print("pin13", get_pin(13));
  """
  def get_pins([pin], lua) do
    case FarmbotFirmware.request({:pin_read, [p: pin]}) do
      {:ok, {_, {:report_pin_value, [p: _, v: v]}}} ->
        {[v], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def get_pins([], lua) do
    get_pins(Enum.to_list(0..69), lua)
  end

  def get_pins(list, lua) do
    case do_get_pins(list) do
      {:ok, contents} ->
        {[contents], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def coordinate([x, y, z], lua)
      when is_number(x) and is_number(y) and is_number(z) do
    {[[{"x", x}, {"y", y}, {"z", z}]], lua}
  end

  defp do_get_pins(nums, acc \\ [])

  defp do_get_pins([p | rest], acc) do
    case FarmbotFirmware.request({:pin_read, [p: p]}) do
      {:ok, {_, {:report_pin_value, [p: ^p, v: v]}}} ->
        do_get_pins(rest, [{to_string(p), v} | acc])

      er ->
        er
    end
  end

  defp do_get_pins([], acc), do: {:ok, Enum.reverse(acc)}
end
