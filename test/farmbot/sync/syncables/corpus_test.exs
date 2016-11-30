defmodule CorpusTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a corpus" do
    {:ok, not_fail} =
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
    assert(fail == {Corpus, :malformed})
    assert(also_fail == {Corpus, :malformed})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{Corpus} Object", fn ->
      Corpus.create!(%{"fake" => "corpus"})
    end
  end

  test "wont raise an exception" do
    c  = Corpus.create!(%{
      "tag" => 0,
      "args" => %{},
      "nodes" => %{}
      })
    assert c.tag == 0
    assert c.args == %{}
    assert c.nodes == %{}
  end
end
