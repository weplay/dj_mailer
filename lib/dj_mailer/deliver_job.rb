module DJMailer

  class DeliverJob < Struct.new(:destinations, :sender, :encoded_mail, :priority)

    def perform
      if destinations.size > 1
        deliver_to_multiple_recipients
      else
        deliver_to_one_recipient(destinations.first)
      end
    end

    def deliver_to_multiple_recipients
      destinations.each do |destination|
        job = DeliverJob.new([destination], sender, encoded_mail, priority)
        Delayed::Job.enqueue(job, priority)
      end
    end

    def deliver_to_one_recipient(destination)
      if DJMailer.smtp_delivery_enabled
        with_smtp_connection do |smtp|
          result = smtp.send_message(encoded_mail, sender, destination)
          Rails.logger.debug "Sent email from %s to %s: %p" % [sender, destination, result]
        end
      end

      Email.create!(:from => sender, :to => destination, :mail => encoded_mail, :sent_at => Time.now)
    end

    def with_smtp_connection(&block)
      smtp = Net::SMTP.new(smtp_settings[:address], smtp_settings[:port])

      if smtp_settings[:enable_starttls_auto] && smtp.respond_to?(:enable_starttls_auto)
        smtp.enable_starttls_auto
      end

      smtp.start(
        smtp_settings[:domain],
        smtp_settings[:user_name],
        smtp_settings[:password],
        smtp_settings[:authentication],
        &block
      )
    end

    def smtp_settings
      ActionMailer::Base.smtp_settings
    end

  end

end
