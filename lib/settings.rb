require 'settingslogic'
module FBPi
  class Settings < Settingslogic
    source "storage/settings.yml"
    namespace ENV['FBENV'] || 'production'

    def self.save
      original_file = YAML.load_file(source)
      original_file[namespace] = Hash[self]
      yml_string = original_file.to_yaml
      File.open(source, 'w') { |f| f.write(original_file.to_yaml) }
      self
    end
  end
end
