module Mailbot
  module Discord
    class Connection < Mailbot::Connection
      attr_reader :bot, :thread

      def initialize
        initialize_bot
        initialize_commands
      end

      # Helper to delegate channel lookups to the underlying client.
      #
      # @param [Integer] id The Discord channel ID.
      #
      # @return [Discordrb::Channel] The located Discord channel.
      def channel(id)
        bot.channel(id)
      end

      # Helper to delegate message sending to the underlying client.
      #
      # @param [Integer] channel_id The Discord channel ID.
      # @param [String] content The text of the message. Max 2000 characters.
      # @param [true, false] tts If the message should be text-to-speech.
      # @param [Hash, Discordrb::Webhooks::Embed, nil] The rich embed to send.
      #
      # @return [Discordrb::Message] The message that was sent
      def send_message(channel_id, content, tts = false, embed = nil)
        bot.send_message(channel_id, content, tts, embed)
      end

      def start
        bot.run(:async)

        @thread = Thread.start do
          if !bot.connected?
            Mailbot.logger.info 'Attempting to reconnect to Discord.'
            bot.run(:async)
          end

          sleep(60)
        end
      end

      def stop
        return unless thread

        Mailbot.logger.info 'Disconnecting from Discord...'
        no_sync = Mailbot.env == 'production' ? true : false
        bot.stop(no_sync)
        bot.sync
        Mailbot.logger.info 'Disconnected from Discord.'
        thread.exit
      end

      private

      def initialize_bot
        config = Mailbot.configuration.discord

        @bot = Discordrb::Commands::CommandBot.new(token:     config.token,
                                                   client_id: config.client_id,
                                                   prefix:    '!')

        bot.disconnected do |event|
          Mailbot.logger.info("Disconnected from Discord due to #{event.inspect}")
        end

        bot.mention do |event|
          context      = initialize_context(event)
          parser       = Mailbot::NLP::Parser.new(event.content)
          action_klass = parser.parse

          context.command = action_klass&.new(context.user, parser.arguments)

          result = context.command&.execute(context)

          event.channel.send_message(result) if context.service.nil?
        end
      end

      def initialize_commands
        Mailbot::Commands.for_platform(:discord).each do |command_klass|
          register_command(command_klass)
        end
      end

      def initialize_context(event)
        context = Context.new

        # TODO: Persist the user. Probably need to adjust the model.
        context.user    = Mailbot::Models::User.new(name: event.author.username)
        context.service = event.server && Mailbot::Models::Community.find_or_create_by(name: event.server.id)
        context.event   = event

        context
      end

      def register_command(command_klass)
        bot.command(command_klass.command_name.to_sym) do |event, *args|
          context = initialize_context(event)

          result = command_klass.new(context.user, args).execute(context)

          context.service.nil? ? result : nil
        end
      end
    end
  end
end
