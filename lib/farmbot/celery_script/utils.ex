defmodule Farmbot.CeleryScript.Utils do
  @moduledoc false
  alias Farmbot.Firmware.Vec3
  alias Farmbot.CeleryScript.AST
  import Ecto.Query

  def ast_to_vec3(%AST{kind: AST.Node.Tool} = ast) do
    tool_id = ast.args.tool_id
    case Farmbot.Repo.A.one(from p in Farmbot.Repo.Point, where: p.tool_id == ^tool_id) do
      %{x: x, y: y, z: z} ->
        {:ok, new_vec3(x, y, z)}
      nil -> {:error, "Could not find tool by id: #{tool_id}"}
    end
  end

  def ast_to_vec3(%AST{kind: AST.Node.Coordinate, args: %{x: x, y: y, z: z}}) do
    {:ok, new_vec3(x, y, z)}
  end

  def ast_to_vec3(%Vec3{} = vec3), do: {:ok, vec3}

  def ast_to_vec3(%AST{kind: kind}) do
    {:error, "can not convert: #{kind} to a coordinate."}
  end

  def vec3_math(%Vec3{x: xa, y: ya, z: za}, fun, %Vec3{x: xb, y: yb, z: zb}) do
    res_x = apply(Kernel, fun, [xa, xb])
    res_y = apply(Kernel, fun, [ya, yb])
    res_z = apply(Kernel, fun, [za, zb])
    new_vec3(res_x, res_y, res_z)
  end

  def new_vec3(x, y, z), do: struct(Vec3, [x: x, y: y, z: z])
end
