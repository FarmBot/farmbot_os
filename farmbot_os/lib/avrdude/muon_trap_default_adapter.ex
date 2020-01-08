defmodule Avrdude.MuonTrapDefaultAdapter do
  @behaviour Avrdude.MuonTrapAdapter

  @impl Avrdude.MuonTrapAdapter
  defdelegate cmd(exe, args, options), to: MuonTrap, as: :cmd
end
