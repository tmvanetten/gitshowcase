module MailchimpUser
  extend ActiveSupport::Concern

  class_methods do
    def mailchimp_key
      ENV['MAILCHIMP_KEY']
    end

    def mailchimp_list
      ENV['MAILCHIMP_LIST_ID']
    end

    def mailchimp_client
      @mailchimp_client = Gibbon::Request.new(api_key: mailchimp_key)
    end

    def mailchimp_client_list
      @mailchimp_client_list = mailchimp_client.lists mailchimp_list
    end

    def mailchimp_enabled?
      return mailchimp_key.present? && mailchimp_list.present?
    end
  end

  included do
    after_update :mailchimp_subscribe_changed
    after_destroy :mailchimp_unsubscribe
  end

  def mailchimp_member
    self.class.mailchimp_client_list.members(downcase_hashed_email)
  end

  def mailchimp_subscribe
    return unless self.class.mailchimp_enabled?

    body = {
        email_address: email,
        status: 'subscribed',
        merge_fields: {
            FNAME: first_name,
            NAME: display_name,
            USERNAME: username
        }
    }

    body[:merge_fields][:location] = location if location.present?

    mailchimp_member.upsert(body: body)
  end

  def mailchimp_subscribe_changed
    mailchimp_subscribe if email_changed?
  end

  def mailchimp_unsubscribe
    return unless self.class.mailchimp_enabled?

    mailchimp_member.delete
  end

  protected

  def downcase_hashed_email
    Digest::MD5.hexdigest email.downcase
  end
end
