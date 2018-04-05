# if we exclude any tags in the init args don't bother running the preflight_checks.
unless '--exclude farmbot_api' in :init.get_plain_arguments() do
  FarmbotTestSupport.preflight_checks()
end
FarmbotTestSupport.wait_for_firmware()

# Start ExUnit.
ExUnit.start()
