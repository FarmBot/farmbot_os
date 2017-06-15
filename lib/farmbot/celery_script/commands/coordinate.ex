defmodule Farmbot.CeleryScript.Command.Coordinate do
  @moduledoc """
    Coordinate Object
  """

  alias Farmbot.CeleryScript.{Command, Ast, Types}
  @behaviour Command

  @doc ~s"""
    coodinate
      args: %{x: integer, y: integer, z: integer}
      body: []
  """
  @type coord_args :: %{x: Types.coord_x, y: Types.coord_y, z: Types.coord_z}
  @spec run(coord_args, [], Context.t) :: Context.t
  def run(%{x: _x, y: _y, z: _z} = args, [], context) do
    result = %Ast{kind: "coordinate", args: args, body: []}
    Farmbot.Context.push_data(context, result)
  end
end
