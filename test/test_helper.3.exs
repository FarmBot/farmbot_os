Application.ensure_all_started(:farmbot)
Application.ensure_all_started(:mimic)

timeout = System.get_env("EXUNIT_TIMEOUT") || "5000"
System.put_env("LOG_SILENCE", "true")

ExUnit.configure(
  max_cases: 1,
  assert_receive_timeout: String.to_integer(timeout)
)

ExUnit.start()
