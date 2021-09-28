defmodule FarmbotCore.Celery.Compiler.UpdateResource do
  alias FarmbotCore.Celery.{AST, DotProps}

  def update_resource(%AST{args: args, body: body}, cs_scope) do
    update = unpair(body, %{})
    quote location: :keep do
      me = unquote(__MODULE__)
      variable = unquote(Map.fetch!(args, :resource))
      update = unquote(update)
      cs_scope = unquote(cs_scope)
      case variable do
        %FarmbotCore.Celery.AST{kind: :identifier} ->
          args = Map.fetch!(variable, :args)
          label = Map.fetch!(args, :label)
          {:ok, resource} = FarmbotCore.Celery.Compiler.Scope.fetch!(cs_scope, label)
          me.do_update(resource, update)

        %FarmbotCore.Celery.AST{kind: :point} ->
          me.do_update(variable.args(), update)

        %FarmbotCore.Celery.AST{kind: :resource} ->
          me.do_update(variable.args(), update)

        res ->
          raise "Resource error. Please notfiy support: #{inspect(res)}"
      end
    end
  end

  def do_update(%{pointer_id: id, pointer_type: kind}, update_params) do
    FarmbotCore.Celery.SysCalls.update_resource(kind, id, update_params)
  end

  def do_update(%{resource_id: id, resource_type: kind}, update_params) do
    FarmbotCore.Celery.SysCalls.update_resource(kind, id, update_params)
  end

  def do_update(%{args: %{pointer_id: id, pointer_type: k}}, update_params) do
    FarmbotCore.Celery.SysCalls.update_resource(k, id, update_params)
  end

  def do_update(other, update) do
    raise String.trim("""
          MARK AS can only be used to mark resources like plants and devices.
          It cannot be used on things like coordinates.
          Ensure that your sequences and farm events us MARK AS on plants and not
          coordinates (#{inspect(other)} / #{inspect(update)})
          """)
  end

  defp unpair([pair | rest], acc) do
    key = Map.fetch!(pair.args, :label)
    val = Map.fetch!(pair.args, :value)
    next_acc = Map.merge(acc, DotProps.create(key, val))
    unpair(rest, next_acc)
  end

  defp unpair([], acc) do
    acc
  end
end
