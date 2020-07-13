defmodule FarmbotCeleryScript.Compiler.PinControl do
  alias FarmbotCeleryScript.Compiler
  # compiles write_pin
  def write_pin(
        %{args: %{pin_number: num, pin_mode: mode, pin_value: value}},
        env
      ) do
    quote location: :keep do
      pin = unquote(Compiler.compile_ast(num, env))
      mode = unquote(Compiler.compile_ast(mode, env))
      value = unquote(Compiler.compile_ast(value, env))

      with :ok <- FarmbotCeleryScript.SysCalls.write_pin(pin, mode, value) do
        if mode == 0 do
          FarmbotCeleryScript.SysCalls.read_pin(pin, mode)
        else
          FarmbotCeleryScript.SysCalls.log("Pin #{pin} is #{value} (analog)")
        end
      end
    end
  end

  # compiles read_pin
  def read_pin(%{args: %{pin_number: num, pin_mode: mode}}, env) do
    quote location: :keep do
      pin = unquote(Compiler.compile_ast(num, env))
      mode = unquote(Compiler.compile_ast(mode, env))
      FarmbotCeleryScript.SysCalls.read_pin(pin, mode)
    end
  end

  # compiles set_servo_angle
  def set_servo_angle(
        %{args: %{pin_number: pin_number, pin_value: pin_value}},
        env
      ) do
    quote location: :keep do
      pin = unquote(Compiler.compile_ast(pin_number, env))
      angle = unquote(Compiler.compile_ast(pin_value, env))
      FarmbotCeleryScript.SysCalls.log("Writing servo: #{pin}: #{angle}")
      FarmbotCeleryScript.SysCalls.set_servo_angle(pin, angle)
    end
  end

  # compiles set_pin_io_mode
  def set_pin_io_mode(
        %{args: %{pin_number: pin_number, pin_io_mode: mode}},
        env
      ) do
    quote location: :keep do
      pin = unquote(Compiler.compile_ast(pin_number, env))
      mode = unquote(Compiler.compile_ast(mode, env))
      FarmbotCeleryScript.SysCalls.log("Setting pin mode: #{pin}: #{mode}")
      FarmbotCeleryScript.SysCalls.set_pin_io_mode(pin, mode)
    end
  end

  def toggle_pin(%{args: %{pin_number: pin_number}}, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.toggle_pin(unquote(pin_number))
    end
  end
end
