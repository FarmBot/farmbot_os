%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "web/", "apps/"],
        excluded: ["lib/extras/joystick.ex", "lib/farmbot/bot_state/trackers/state_tracker.ex", "lib/mix"]
      }
    }
  ]
}
