defmodule Farmbot.CeleryScript.Utils do
  @moduledoc false
  alias Farmbot.Firmware.Vec3
  alias Farmbot.CeleryScript.AST
  alias AST.Node.{Tool, Coordinate, Point, Nothing}
  alias Farmbot.Repo.Point, as: DBPoint
  import Ecto.Query

  def ast_to_vec3(%AST{kind: Tool} = ast) do
    repo = Farmbot.Repo.current_repo()
    tool_id = ast.args.tool_id
    case repo.one(from p in DBPoint, where: p.tool_id == ^tool_id) do
      %{x: x, y: y, z: z} -> {:ok, new_vec3(x, y, z)}
      nil ->
        case repo.one(from t in Farmbot.Repo.Tool, where: t.id == ^tool_id) do
          %{name: name} ->
            {:error, "#{name} is not currently in a tool slot."}
          nil -> {:error, "Could not find tool by id: #{tool_id}"}
        end
    end
  end

  def ast_to_vec3(%AST{kind: Coordinate, args: %{x: x, y: y, z: z}}) do
    {:ok, new_vec3(x, y, z)}
  end

  def ast_to_vec3(%AST{kind: Point} = ast) do
    point_id = ast.args.pointer_id
    case Farmbot.Repo.current_repo().one(from p in DBPoint, where: p.id == ^point_id) do
      %{x: x, y: y, z: z} ->
        {:ok, new_vec3(x, y, z)}
      nil -> {:error, "Could not find point by id: #{point_id}"}
    end
  end

  def ast_to_vec3(%AST{kind: Nothing}) do
    {:ok, %Vec3{x: 0, y: 0, z: 0}}
  end

  def ast_to_vec3(%Vec3{} = vec3), do: {:ok, vec3}

  def ast_to_vec3(%AST{kind: kind}) do
    {:error, "can not convert: #{kind} to a coordinate."}
  end

  def vec3_math(%Vec3{x: xa, y: ya, z: za}, fun, %Vec3{x: xb, y: yb, z: zb}) do
    res_x = apply(Kernel, fun, [xa || 0, xb || 0])
    res_y = apply(Kernel, fun, [ya || 0, yb || 0])
    res_z = apply(Kernel, fun, [za || 0, zb || 0])
    new_vec3(res_x, res_y, res_z)
  end

  def new_vec3(x, y, z), do: struct(Vec3, [x: x, y: y, z: z])
end
