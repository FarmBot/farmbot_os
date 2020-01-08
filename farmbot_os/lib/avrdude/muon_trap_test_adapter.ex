defmodule Avrdude.MuonTrapTestAdapter do
  @behaviour Avrdude.MuonTrapAdapter

  @impl Avrdude.MuonTrapAdapter
  def cmd(exe, args, options) do
    {exe, args, options}
  end
end
