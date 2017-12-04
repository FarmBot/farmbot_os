# if we exclude any tags in the init args don't bother running the preflight_checks.
unless '--exclude' in :init.get_plain_arguments() do
  FarmbotTestSupport.preflight_checks()
end
Farmbot.Logger.Console.set_verbosity_level(0)

Ecto.Adapters.SQL.Sandbox.mode(Farmbot.Repo.A, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Farmbot.Repo.B, :manual)
FarmbotTestSupport.wait_for_firmware()

# Start ExUnit.
ExUnit.start()
