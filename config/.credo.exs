%{
  configs: [
    %{
      name: "default",
      strict: true,
      color: true,
      files: %{
        included: ["lib/"],
        excluded: ["lib/mix"]
      }
    }
  ]
}
