require 'settingslogic'
module FBPi
  class Settings < Settingslogic
    DEFAULTS = "db/settings.defaults.yml"
    source "db/settings.yml"
    namespace ENV['FBENV'] || 'production'

    def self.save
      defaults = YAML.load_file(DEFAULTS)
      original_file = File.file?(source) ? YAML.load_file(source) : {}
      original_file[namespace] = Hash[self]
      defaults.merge(original_file)
      yml_string = original_file.to_yaml
      File.open(source, 'w') { |f| f.write(original_file.to_yaml) }
      self
    end
  end
end
