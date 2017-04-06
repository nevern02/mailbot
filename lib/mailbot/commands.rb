require 'mailbot/commands/bnet'
require 'mailbot/commands/giveaway'
require 'mailbot/commands/roll'
require 'mailbot/commands/steam'
require 'mailbot/commands/trivia'
require 'mailbot/commands/trivia/game'
require 'mailbot/commands/trivia/start'
require 'mailbot/commands/trivia/answer'

module Mailbot
  module Commands
    COMMANDS = {
      bnet:     Commands::Bnet,
      roll:     Commands::Roll,
      steam:    Commands::Steam,
      trivia:   Commands::Trivia,
      giveaway: Commands::Giveaway
    }

    def self.from_input(user, message)
      return unless message[0] == '!'

      command, *args = message.split
      command        = command[1..-1] # strip the !
      klass          = COMMANDS[command.to_sym]

      klass && klass.new(user, args)
    end
  end
end