require 'highline'
require 'pry'
require_relative './lib/settings'
require './lib/rest_client'
require './lib/secret_file'
puts File.read("setup/banner.txt")
app = HighLine.new

# ====================================================================
# STEP 1:
# - Get token
# - Store "secrets"

api_url = app.ask(File.read("setup/api_question_text.txt")) do |q|
  q.default = "my.farmbot.io"
end

did_register = app.agree("Did you register for an account at #{api_url}? (y/n)", true)
unless did_register
  puts "Please register for an account at #{api_url} before proceeding."
  exit
end
begin
  email = app.ask "Enter registration email used at #{api_url}:"
  raise "Invalid email address" unless email.include?("@")
  password = app.ask("Enter password for Farmbot account #{email} : ") { |q| q.echo = "x" }
  puts "Fetching token..."
  token = FbResource::Client.get_token(email:    email,
                                       password: password,
                                       url:      api_url)
rescue => e
  puts "UH OH! Something went wrong while logging in: "
  puts e.message
  puts "Please try again or copy/paste the error to Rick@FarmBot.io"
  retry
end
puts "Saving data..."
FBPi::Settings["token"] = token
FBPi::Settings.save
client = FBPi::RPiRestClient.new(token)
puts "Encrypting data..."
SecretFile.save_password(client.public_key, email, password)

# = FACTORY RESET ==============================================================

del = app.agree(File.read("setup/factory_reset.txt"), false)
del_confirm = app.agree("Are you sure?", false)

if (del && del_confirm)
  puts "reseting...."
  `rake db:reset`
  `rm db/*.pstore`
else
end
puts "Installing dependencies"
`bundle install`
puts "Setup is complete! You may now run `ruby setup.rb` to initialize the bot."
