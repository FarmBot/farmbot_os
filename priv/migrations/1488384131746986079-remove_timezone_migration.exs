defmodule RemoveTimeZone do
  def run(json) do
    configuration = json["configuration"]
    new_config = if configuration["timezone"] do
      Map.delete(configuration, "timezone")
    else
      configuration 
    end
    %{json | "configuration" => new_config}
  end
end
