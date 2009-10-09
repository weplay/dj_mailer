module DJMailer

  class Base < ActionMailer::Base

    cattr_accessor :custom_email_headers
    self.custom_email_headers = {}

    superclass_delegating_accessor :delayed_job_priority
    self.delayed_job_priority = 0

    cattr_accessor :batch_size
    self.batch_size = 100

    cattr_accessor :after_create_filter
    cattr_accessor :before_delivery_filter

    def perform_delivery_delayed_job(mail)
      sender = (mail['return-path'] && mail['return-path'].spec) || (mail.from([]).any? && mail.from.first)
      mail.destinations([]).in_groups_of(batch_size, false).each do |destinations|
        job = DeliverJob.new(destinations, sender, mail.encoded, self.class.delayed_job_priority)
        Delayed::Job.enqueue(job, self.class.delayed_job_priority)
      end
    end

    def create!(*args)
      mail = super

      self.class.custom_email_headers.each do |name, value|
        mail[name] = value
      end

      self.class.after_create_filter.call(mail) if self.class.after_create_filter
      return mail
    end

    def deliver!
      if !self.class.before_delivery_filter || self.class.before_delivery_filter.call(mail)
        logger.debug "Passed delivery filter, delivering mail."
        super
      else
        logger.debug "Not delivering mail to #{mail.to} because delivery filter failed."
      end
    end

  end

end