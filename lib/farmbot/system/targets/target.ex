target = Mix.Project.config[:target]
unless target == "host" do
  nerves_common_path = "lib/farmbot/system/targets/nerves_common"
  nc_files = File.ls! nerves_common_path
  for file <- nc_files, do: Code.eval_file(file, nerves_common_path)
end

path = case Mix.env() do
  :test ->
    "lib/farmbot/system/targets/#{target}_test"
  _ ->
    "lib/farmbot/system/targets/#{target}"
end

files = File.ls! path
for file <- files, do: Code.eval_file(file, path)
