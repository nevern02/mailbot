module Mailbot
  # Data structure representing a parsed/tokenized message from some platform.
  #
  # @attr_accessor [Mailbot::Models::User] user the user who sent the message
  # @attr_accessor [Mailbot::Models::Channel, Mailbot::Models::Community] service either the Channel (Twitch)
  #   or the Community (Discord) this message originated from
  # @attr_accessor [Object, #execute] command an object that responds to #execute from the Mailbot::Commands namespace
  # @attr_accessor [Discordrb::Events::MessageEvent, nil] event the Discord event for this message (always nil for Twitch)
  class Context
    attr_accessor :user, :service, :command, :event

    # @param [String] message the message to send to @channel
    #
    # @return [nil]
    def send_string(message)
      Mailbot.logger.info("Sending #{message} to #{service.inspect}")
      service && service.send_message(message, channel: event && event.channel)
      message
    end
  end
end
