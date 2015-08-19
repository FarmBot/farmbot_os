require_relative 'abstract_controller'
require 'farmbot-resource'
require_relative '../command_objects/commands'

module FBPi
  # This controller will destroy all Schedules, Sequences and Steps on the bot
  # and replace them with the most recent version that exists remotely on the
  # Web App.
  class SyncSequenceController < AbstractController
    def call
      SyncBot.run!(bot: bot)
      reply "sync_sequence"
    rescue FbResource::FetchError => error
      reply "error", error: error.message, hint: "The Webapp is having issues"
    end
  end
end
