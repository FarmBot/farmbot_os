require_relative 'config'

module FbResource
  class SequenceFetchError < Exception; end
  class Client
    attr_reader :config

    def initialize(&blk)
      @config = Config.new
      yield(@config)
    end

    def fetch_schedules
      options = { url: @config.url, token: @config.token, uuid: @config.uuid }
      Schedules::Index.new(options).run
    end
  end
end
