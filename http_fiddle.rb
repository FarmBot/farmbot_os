require 'active_record'
require 'pry'
require_relative 'lib/command_objects/commands'
require_relative 'lib/fb_resource/fb_resource'
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3',
                                        :database => './db/db.sqlite3')

client = FbResource::Client.new do |config|
  config.uuid  = '1b6d9043-8949-4199-b13e-58ae6e2ea181'
  config.token = '229458c0a7044b5ceca92e9257ac32156baa63c2'
  config.url   = 'http://localhost:3000'
end

schedules = client.fetch_schedules

begin
  results   = FBPi::CreateSchedule.run!(schedules.first)
rescue Exception => e
  binding.pry
end
''
binding.pry

puts '?'
