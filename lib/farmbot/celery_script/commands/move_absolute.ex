defmodule Farmbot.CeleryScript.Command.MoveAbsolute do
  @moduledoc """
    Update Farmware
  """

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  alias Farmbot.Lib.Maths
  require Logger
  alias Farmbot.Serial.Handler, as: UartHan
  # alias Farmbot.Serial.Gcode.Parser, as: GParser
  @behaviour Command

  @type coordinate_ast :: Command.Coordinate.t

  @doc ~s"""
    move_absolute to a prticular position.
      args: %{
        speed: integer,
        offset: coordinate_ast | Ast.t
        location: coordinate_ast | Ast.t
      },
      body: []
  """
  @type move_absolute_args :: %{
    speed: integer,
    offset: coordinate_ast | Ast.t,
    location: coordinate_ast | Ast.t
  }
  @spec run(move_absolute_args, []) :: no_return
  def run(%{speed: s, offset: offset, location: location}, []) do
    with %Ast{kind: "coordinate", args: %{x: xa, y: ya, z: za}, body: []} <-
            Command.ast_to_coord(location),
         %Ast{kind: "coordinate", args: %{x: xb, y: yb, z: zb}, body: []} <-
            Command.ast_to_coord(offset)
    do
      do_move({xa, ya, za}, {xb, yb, zb}, s)
    else
      error -> Logger.error ">> error doing Move absolute: #{inspect error}"
    end
  end

  defp do_move({xa, ya, za}, {xb, yb, zb}, speed) do
    { combined_x, combined_y, combined_z } = { xa + xb, ya + yb, za + zb }
    {x, y, z} = do_math(combined_x, combined_y, combined_z)
    "G00 X#{x} Y#{y} Z#{z} S#{speed}" |> UartHan.write
    # ensure_position(combined_x, combined_y, combined_z)
  end

  defp do_math(combined_x, combined_y, combined_z) do
    { Maths.mm_to_steps(combined_x, spm(:x)),
      Maths.mm_to_steps(combined_y, spm(:y)),
      Maths.mm_to_steps(combined_z, spm(:z)) }
  end

  defp spm(xyz), do:
    "steps_per_mm_#{xyz}"
    |> String.to_atom
    |> Farmbot.BotState.get_config()

  # @doc """
  #   Make sure we are at the correct position before moving on.
  # """
  # def ensure_position(expected_x, expected_y, expected_z, retries \\ 0)
  # def ensure_position(_,_,_, retries) when retries > 10 do
  #   Logger.error ">> Movement still not completed. Your bot might be stuck."
  #   {:error, :not_moving}
  # end
  #
  # def ensure_position(expected_x, expected_y, expected_z, retries) do
  #   [cur_x, cur_y, cur_z] = Farmbot.BotState.get_current_pos
  #   if {expected_x, expected_y, expected_z} == {cur_x, cur_y, cur_z} do
  #     Logger.info ">> Completed movement: " <>
  #       "(#{expected_x}, #{expected_y}, #{expected_z})"
  #     :ok
  #   else
  #     Logger.info ">> Movement not complete: " <>
  #       "(#{expected_x}, #{expected_y}, #{expected_z})"
  #     Process.sleep(500)
  #     ensure_position(expected_x, expected_y, expected_z, retries + 1)
  #   end
  # end

end
