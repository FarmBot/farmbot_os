Application.ensure_all_started(:mimic)

[
  FarmbotCeleryScript.SysCalls,
  FarmbotCeleryScript.SpecialValue,
  FarmbotCeleryScript.SysCalls.Stubs
]
|> Enum.map(&Mimic.copy/1)

ExUnit.configure(max_cases: 1)
ExUnit.start()
