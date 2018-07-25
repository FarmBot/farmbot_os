use Mix.Config

cond do
  System.get_env("CIRCLECI") ->
    Mix.shell.info [:green, "Using circle ci config."]
    import_config("auth_secret_ci.exs")
  File.exists?("config/host/auth_secret_test.exs") ->
    import_config("auth_secret_test.exs")
  true ->
    Mix.raise("You need to configure your test environment.\r\n")
end
