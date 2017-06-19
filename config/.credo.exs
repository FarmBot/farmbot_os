%{
  configs: [
    %{
      name: "default",
      strict: true,
      color: true,
      files: %{
        included: ["lib/"],
        excluded: [
          "lib/mix",
          "lib/farmbot/sysformatter.ex",
          "lib/logger/backends/farmbot_logger.ex",
          "lib/farmbot/system/targets",
          "lib/farmbot/sync/syncable.ex",
        ]
      }
    }
  ]
}
