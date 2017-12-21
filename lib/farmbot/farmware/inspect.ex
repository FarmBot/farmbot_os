defimpl Inspect, for: Farmbot.Farmware do
  def inspect(%{name: name, version: version}, _), do: "#Farmware<#{name}(#{version})>"
  def inspect(_thing, _), do: "#Farmware<:invalid>"
end

defimpl Inspect, for: Farmbot.Farmware.Meta do
  def inspect(meta, _), do: "#FarmwareMeta<#{meta.description}>"
end
