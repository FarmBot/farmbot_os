module FbResource
  module Schedules
    SCHEDULE_PATH = '/api/schedules/'
    SEQUENCE_PATH = '/api/sequences/'

    class Index
      attr_accessor :url, :creds, :schedules

      def initialize(url:, token:, uuid:)
        @url, @creds = url, {bot_token: token, bot_uuid: uuid}
      end

      def run
        @schedules = Http
          .get(url + SCHEDULE_PATH, creds)
          .no { |error| puts error }
          .ok { |a,b,c| get_steps(a) }
      end

      def get_steps(schedules)
          # /api/sequences/55310c9f70726f2d1c050000/steps
        schedules
          .map { |scd| url + SEQUENCE_PATH + "#{scd["sequence_id"]}/steps" }
          .tap { |qqq| binding.pry }
          .map { |url| FbResource::Http.get(url, creds) }
          .map { |res| res.no{ |e| raise(SequenceFetchError, e) } }
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
