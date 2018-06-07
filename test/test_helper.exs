# if we exclude any tags in the init args don't bother running the preflight_checks.
unless '--exclude' in :init.get_plain_arguments() do
  FarmbotTestSupport.preflight_checks()
end

# Start ExUnit.
ExUnit.start()
