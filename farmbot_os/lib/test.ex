defmodule Test do
  import Ecto.Query
  alias Farmbot.CeleryScript
  alias CeleryScript.RunTime.FarmProc
  import CeleryScript.Utils

  def test(amnt) do
    state = :sys.get_state(CeleryScript.RunTime)
    fun = state.process_io_layer
    seq = Farmbot.Asset.Repo.one(from s in Farmbot.Asset.Sequence, where: s.name == "new sequence 12")
    ast = CeleryScript.AST.decode(seq)
    heap = CeleryScript.AST.slice(ast)
    page = addr(seq.id)
    proc0 = FarmProc.new(fun, page, heap)
    reduce(proc0, amnt)
  end

  def reduce(proc, count, acc \\ [])

  def reduce(proc, 0, acc) do
    [proc | acc]
  end

  def reduce(proc, count, acc) do
    next = FarmProc.step(proc)
    if next.status == :waiting do
      reduce(next, count, acc)
    else
      reduce(next, count - 1, [proc | acc])
    end
  end
end
