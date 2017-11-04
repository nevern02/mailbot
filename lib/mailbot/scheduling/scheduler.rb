module Mailbot
  module Scheduling
    class Scheduler
      attr_reader :thread, :jobs

      def initialize
        @jobs = []

        # TODO: Move this
        add(Mailbot::Scheduling::Kadgar.new(1800))
      end

      def add(job)
        @jobs << job
      end

      def start
        Mailbot.logger.info 'Starting scheduler...'

        @thread = Thread.start do
          loop do
            Mailbot.logger.info("Running jobs...")

            jobs.each do |job|
              next unless job.ready?

              Mailbot.logger.info("Running #{job.class}")
              job.perform
            end

            Mailbot.logger.info("Done running jobs...")

            sleep(300)
          end
        end
      end

      def stop
        Mailbot.logger.info 'Stopping scheduler...'
        thread.exit
        Mailbot.logger.info 'Scheduler stopped.'
      end
    end
  end
end
