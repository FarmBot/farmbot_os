module FbResource
  module Schedules
    SCHEDULE_URL = '/api/schedules/'
    SEQUENCE_URL = '/api/sequences/'
    class Index
      attr_accessor :url, :creds, :schedules

      def initialize(url:, token:, uuid:)
        @url, @creds = url + SCHEDULE_URL, {bot_token: token, bot_uuid: uuid}
      end

      def run
        @schedules = Http
          .get(url, creds)
          .no { |error| puts error }
          .ok { |a,b,c| get_steps(a) }
      end

      def get_steps(schedules)
        resp = FbResource::Http.get(url, creds)
        schedules
          .map { |sd| "#{SEQUENCE_URL}#{sd["sequence_id"]}/steps" }
          .map { |url| resp.no{raise SequenceFetchError} }
          .map { |res| res.obj }
          .each_with_index
          .map do |s, i|
            schedules[i].tap do |that|
              that["sequence"] = {'name' => that['sequence_name'], 'steps' => s}
            end
          end
      end

    end
  end
end
