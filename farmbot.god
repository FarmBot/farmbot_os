God.watch do |w|
  w.name = "farmbot_rpi_controller"
  w.dir = File.expand_path(File.dirname(__FILE__))
  w.start = "ruby farmbot.rb"
  w.keepalive
end
