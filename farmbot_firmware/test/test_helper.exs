Application.ensure_all_started(:mimic)
Mimic.copy(File)
ExUnit.start()
