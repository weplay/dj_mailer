module DJMailer
  # Actually deliver emails via SMTP when the delayed jobs are processed.
  # Enabled by default. It can be useful to disable this in test environments.
  mattr_accessor :smtp_delivery_enabled
  self.smtp_delivery_enabled = true
end
