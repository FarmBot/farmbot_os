defmodule FarmbotOS.Celery.DotProps do
  @dot "."
  @doc ~S"""
  Takes a "dotted" key and val.
  Returns deeply nested hash.

  ## Examples

      iex> create("foo.bar.baz", 321)
      %{"foo" => %{"bar" => %{"baz" => 321}}}

      iex> create("foo", "bar")
      %{"foo" => "bar"}
  """
  def create(dotted, val) do
    [key | list] = dotted |> String.split(@dot) |> Enum.reverse()

    Enum.reduce(list, %{key => val}, fn next_key, acc ->
      %{next_key => acc}
    end)
  end
end
