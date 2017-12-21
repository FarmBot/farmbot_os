defmodule Farmbot.TestSupport.FarmwareFactory do

  def generate(opts) do
    meta = struct(Farmbot.Farmware.Meta,
      [author: Faker.App.author(), language: "python", description: ""])
    fw = struct(Farmbot.Farmware,
      [name: Faker.App.name(),
        version: version(),
        min_os_version_major: 6,
        url: Faker.Internet.url(),
        zip: Faker.Internet.url(),
        executable: Faker.File.file_name(),
        args: [],
        config: [],
        meta: meta
    ])

    do_update(fw, opts)
  end

  #FIXME(Connor) https://github.com/igas/faker/issues/125
  def version do
    case Version.parse(Faker.App.semver) do
      {:ok, %Version{} = ver} -> ver
      _ -> version()
    end
  end

  defp do_update(fw, opts)
  defp do_update(fw, [{key, val} | rest]) do
    if key in Map.keys(fw) do
      do_update(Map.put(fw, key, val), rest)
    else
      do_update(fw, rest)
    end
  end

  defp do_update(fw, []), do: fw
end
