require 'settingslogic'
module FBPi
  class Settings < Settingslogic
    DEFAULT  = "db/settings.defaults.yml"
    CURRENT  = "db/settings.yml"
    if !File.file?(CURRENT)
      puts "Building settings.yml for first time."
      File.open(CURRENT, "w") { |f| f.write(File.read(DEFAULT)) }
    end

    source CURRENT
    namespace ENV['FBENV'] || 'production'


    def self.save
      original_file = YAML.load_file(source)
      original_file[namespace] = Hash[self]
      yml_string = original_file.to_yaml
      File.open(source, 'w') { |f| f.write(yml_string) }
      self
    end
  end
end
