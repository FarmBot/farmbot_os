use Mix.Config

# You should copy this file to config/host/auth_secret.exs
# And make sure to configure the credentials to something that makes sense.

config :farmbot_os, :authorization,
  email: "admin@admin.com",
  password: "password123",
  server: "http://localhost:3000"