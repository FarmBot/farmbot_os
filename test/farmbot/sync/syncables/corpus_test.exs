defmodule CorpusTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a corpus" do
    not_fail =
      Corpus.create(%{
        "tag" => 0,
        "args" => %{},
        "nodes" => %{}
        })
    assert(not_fail.tag == 0)
    assert(not_fail.args == %{})
    assert(not_fail.nodes == %{})
  end

  test "does not build a corpus" do
    fail = Corpus.create(%{"fake" => "corpus"})
    also_fail = Corpus.create(:wrong_type)
    assert(fail == :error)
    assert(also_fail == :error)
  end
end
