defmodule UserSettings do
  def run(json) do
    configuration = json["configuration"]
    if configuration["user_env"] do
      # if the already exist its fine
      json
    else
      new_config = Map.put(configuration, "user_env", %{})
      %{json | "configuration" => new_config}
    end
  end
end
