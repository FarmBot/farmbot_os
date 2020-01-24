Application.ensure_all_started(:mimic)
Mimic.copy(FarmbotCeleryScript.SysCalls.Stubs)
ExUnit.start()
