defmodule Farmbot.CeleryScript.Command.MoveAbsolute do
  @moduledoc """
    Update Farmware
  """

  alias      Farmbot.CeleryScript.{Command, Types}
  import     Command, only: [ast_to_coord: 2]
  alias      Farmbot.Lib.Maths
  require    Logger
  alias      Farmbot.Serial.Handler, as: UartHan
  alias      Farmbot.Context
  @behaviour Command

  @type coordinate_ast :: Types.coord_ast

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
    offset: coordinate_ast   | Types.ast,
    location: coordinate_ast | Types.ast
  }
  @spec run(move_absolute_args, [], Context.t) :: Context.t
  def run(%{speed: speed, offset: offset, location: location}, _, ctx) do
    Logger.info "Doing movement.", type: :info
    new_context              = ast_to_coord(ctx, location)
    {location, new_context1} = Farmbot.Context.pop_data(new_context)

    new_context2             = ast_to_coord(new_context1, offset)
    {offset, new_context3}   = Farmbot.Context.pop_data(new_context2)

    {xa, ya, za} = {location.args.x, location.args.y, location.args.z}
    {xb, yb, zb} = {offset.args.x,   offset.args.y,    offset.args.z }
    { combined_x, combined_y, combined_z } = { xa + xb, ya + yb, za + zb }
    {x, y, z} = do_math(combined_x, combined_y, combined_z, new_context3)
    UartHan.write(new_context3, "G00 X#{x} Y#{y} Z#{z} S#{speed}")
    max = Farmbot.BotState.get_config(new_context3, :max_movement_retries)
    new_context3 |> ensure_position(
        {combined_x, combined_y,combined_z},
        {x, y, z, speed},
        max)
  end

  defp ensure_position(context,
    exp_pos_mm, goto_pos_steps, max_retries, retries \\ 0)

  defp ensure_position(context, exp_pos_mm, _, 0, _) do
    case do_compare_pos(context, exp_pos_mm) do
      true  -> context
      false -> do_raise(context, exp_pos_mm)
    end
  end

  defp ensure_position(context, exp_pos_mm, _, max_retries, retries)
  when max_retries == retries do
    do_raise(context, exp_pos_mm)
  end

  defp ensure_position(context,
    exp_pos_mm, goto_pos_steps, max_retries, retries)
  do
    case do_compare_pos(context, exp_pos_mm) do
      true  -> context
      false ->
        {goto_steps_x, goto_steps_y, goto_steps_z, speed} = goto_pos_steps
        Farmbot.CeleryScript.Command.do_wait_for_serial(context)
        UartHan.write(context,
          "G00 X#{goto_steps_x} Y#{goto_steps_y} Z#{goto_steps_z} S#{speed}")
        ensure_position(context, exp_pos_mm, goto_pos_steps, max_retries, retries + 1)
    end
  end

  defp do_raise(context, {exp_mm_x, exp_mm_y, exp_mm_z}) do
    raise Farmbot.CeleryScript.Error, context: context,
      message: "failed to move to: (#{exp_mm_x}, #{exp_mm_y}, #{exp_mm_z})"
  end

  defp do_compare_pos(context, {exp_mm_x, exp_mm_y, exp_mm_z}) do
    [act_mm_x, act_mm_y, act_mm_z] = Farmbot.BotState.get_current_pos(context)
    {exp_mm_x, exp_mm_y, exp_mm_z} == {act_mm_x, act_mm_y, act_mm_z}
  end

  defp do_math(combined_x, combined_y, combined_z, context) do
    { Maths.mm_to_steps(combined_x, spm(:x, context)),
      Maths.mm_to_steps(combined_y, spm(:y, context)),
      Maths.mm_to_steps(combined_z, spm(:z, context)) }
  end

  defp spm(xyz, %Farmbot.Context{} = ctx) do
    thing = "steps_per_mm_#{xyz}" |> String.to_atom
    Farmbot.BotState.get_config(ctx, thing)
  end
end
