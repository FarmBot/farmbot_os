defmodule FarmbotCeleryScript.Corpus.ArgTest do
  use ExUnit.Case, async: true
  alias FarmbotCeleryScript.Corpus

  test "inspect" do
    assert "#Arg<_then [execute, nothing]>" = inspect(Corpus.arg("_then"))
  end
end
