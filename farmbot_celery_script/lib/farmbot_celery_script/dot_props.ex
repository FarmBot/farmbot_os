defmodule FarmbotCeleryScript.DotProps do
  def create(key, val) do
    if String.contains?(key, ".") do
      recurse(key, val, %{})
    else
      %{key => val}
    end
  end

  def recurse(_key, _val, acc) do
    acc
  end
end
