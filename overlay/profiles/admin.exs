use Farmbot.Logger
Logger.debug 1, "Setting up local admin profile."

Application.put_env(:farmbot, :authorization, [
  email: "admin@admin.com",
  password: "password123",
  server: "http://localhost:3000"
])

# if Farmbot.Project.target != "host" do
#   update_config_value(:bool, "settings", "first_boot", false)
# end
