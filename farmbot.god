# god -c path/to/simple.god -D
God.watch do |w|
  w.name = "farmbot_rpi_controller"
  w.dir = File.expand_path(File.dirname(__FILE__))
  w.start = "ruby farmbot.rb"

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.interval = 5.seconds
      c.above = 150.megabytes
      c.times = [4, 5] # 4 out of 5 intervals
    end

    restart.condition(:cpu_usage) do |c|
      c.interval = 5.seconds
      c.above = 50.percent
      c.times = [4, 5] # 4 out of 5 intervals
    end
  end
end
