# if we exclude any tags in the init args don't bother running the preflight_checks.
unless '--exclude' in :init.get_plain_arguments() do
  FarmbotTestSupport.preflight_checks()
end

# Start ExUnit.
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Farmbot.Repo.A, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Farmbot.Repo.B, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Farmbot.System.ConfigStorage, :manual)
