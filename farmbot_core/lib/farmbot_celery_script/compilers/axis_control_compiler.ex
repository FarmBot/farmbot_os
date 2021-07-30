defmodule FarmbotCeleryScript.Compiler.AxisControl do
  alias FarmbotCeleryScript.Compiler

  # Compiles move_absolute
  def move_absolute(%{args: %{location: location,offset: offset,speed: speed}}, cs_scope) do
    quote location: :keep do
      # Extract the location arg
      with %{x: locx, y: locy, z: locz} =
             unquote(Compiler.celery_to_elixir(location, cs_scope)),
           # Extract the offset arg
           %{x: offx, y: offy, z: offz} =
             unquote(Compiler.celery_to_elixir(offset, cs_scope)) do
        # Subtract the location from offset.
        # Note: list syntax here for readability.
        [x, y, z] = [
          locx + offx,
          locy + offy,
          locz + offz
        ]

        x_str = FarmbotCeleryScript.FormatUtil.format_float(x)
        y_str = FarmbotCeleryScript.FormatUtil.format_float(y)
        z_str = FarmbotCeleryScript.FormatUtil.format_float(z)

        FarmbotCeleryScript.SysCalls.log(
          "Moving to (#{x_str}, #{y_str}, #{z_str})",
          true
        )

        FarmbotCeleryScript.SysCalls.move_absolute(
          x,
          y,
          z,
          unquote(Compiler.celery_to_elixir(speed, cs_scope))
        )
      end
    end
  end

  # compiles move_relative into move absolute
  def move_relative(%{args: %{x: x, y: y, z: z, speed: speed}}, cs_scope) do
    quote location: :keep do
      with locx when is_number(locx) <- unquote(Compiler.celery_to_elixir(x, cs_scope)),
           locy when is_number(locy) <- unquote(Compiler.celery_to_elixir(y, cs_scope)),
           locz when is_number(locz) <- unquote(Compiler.celery_to_elixir(z, cs_scope)),
           curx when is_number(curx) <-
             FarmbotCeleryScript.SysCalls.get_current_x(),
           cury when is_number(cury) <-
             FarmbotCeleryScript.SysCalls.get_current_y(),
           curz when is_number(curz) <-
             FarmbotCeleryScript.SysCalls.get_current_z() do
        # Combine them
        x = locx + curx
        y = locy + cury
        z = locz + curz
        x_str = FarmbotCeleryScript.FormatUtil.format_float(x)
        y_str = FarmbotCeleryScript.FormatUtil.format_float(y)
        z_str = FarmbotCeleryScript.FormatUtil.format_float(z)

        FarmbotCeleryScript.SysCalls.log(
          "Moving relative to (#{x_str}, #{y_str}, #{z_str})",
          true
        )

        FarmbotCeleryScript.SysCalls.move_absolute(
          x,
          y,
          z,
          unquote(Compiler.celery_to_elixir(speed, cs_scope))
        )
      end
    end
  end

  # Expands find_home(all) into three find_home/1 calls
  def find_home(%{args: %{axis: "all"}}, _cs_scope) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.log("Finding home on all axes", true)

      with :ok <- FarmbotCeleryScript.SysCalls.find_home("z"),
           :ok <- FarmbotCeleryScript.SysCalls.find_home("y") do
        FarmbotCeleryScript.SysCalls.find_home("x")
      end
    end
  end

  # compiles find_home
  def find_home(%{args: %{axis: axis}}, cs_scope) do
    quote location: :keep do
      with axis when axis in ["x", "y", "z"] <-
             unquote(Compiler.celery_to_elixir(axis, cs_scope)) do
        FarmbotCeleryScript.SysCalls.log(
          "Finding home on the #{String.upcase(axis)} axis",
          true
        )

        FarmbotCeleryScript.SysCalls.find_home(axis)
      else
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Expands home(all) into three home/1 calls
  def home(%{args: %{axis: "all", speed: speed}}, cs_scope) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.log("Going to home on all axes", true)

      with speed when is_number(speed) <-
             unquote(Compiler.celery_to_elixir(speed, cs_scope)),
           :ok <- FarmbotCeleryScript.SysCalls.home("z", speed),
           :ok <- FarmbotCeleryScript.SysCalls.home("y", speed) do
        FarmbotCeleryScript.SysCalls.home("x", speed)
      end
    end
  end

  # compiles home
  def home(%{args: %{axis: axis, speed: speed}}, cs_scope) do
    quote location: :keep do
      with axis when axis in ["x", "y", "z"] <-
             unquote(Compiler.celery_to_elixir(axis, cs_scope)),
           speed when is_number(speed) <-
             unquote(Compiler.celery_to_elixir(speed, cs_scope)) do
        FarmbotCeleryScript.SysCalls.log(
          "Going to home on the #{String.upcase(axis)} axis",
          true
        )

        FarmbotCeleryScript.SysCalls.home(axis, speed)
      else
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Expands zero(all) into three zero/1 calls
  def zero(%{args: %{axis: "all"}}, _cs_scope) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.log("Setting home for all axes", true)

      with :ok <- FarmbotCeleryScript.SysCalls.zero("z"),
           :ok <- FarmbotCeleryScript.SysCalls.zero("y") do
        FarmbotCeleryScript.SysCalls.zero("x")
      end
    end
  end

  # compiles zero
  def zero(%{args: %{axis: axis}}, cs_scope) do
    quote location: :keep do
      with axis when axis in ["x", "y", "z"] <-
             unquote(Compiler.celery_to_elixir(axis, cs_scope)) do
        FarmbotCeleryScript.SysCalls.log(
          "Setting home for the #{String.upcase(axis)} axis",
          true
        )

        FarmbotCeleryScript.SysCalls.zero(axis)
      else
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Expands calibrate(all) into three calibrate/1 calls
  def calibrate(%{args: %{axis: "all"}}, _cs_scope) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.log("Finding length of all axes", true)

      with :ok <- FarmbotCeleryScript.SysCalls.calibrate("z"),
           :ok <- FarmbotCeleryScript.SysCalls.calibrate("y") do
        FarmbotCeleryScript.SysCalls.calibrate("x")
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  # compiles calibrate
  def calibrate(%{args: %{axis: axis}}, cs_scope) do
    quote location: :keep do
      with axis when axis in ["x", "y", "z"] <-
             unquote(Compiler.celery_to_elixir(axis, cs_scope)) do
        msg = "Determining length of the #{String.upcase(axis)} axis"
        FarmbotCeleryScript.SysCalls.log(msg, true)
        FarmbotCeleryScript.SysCalls.calibrate(axis)
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end
end
