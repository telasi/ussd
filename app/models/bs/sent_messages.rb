# -*- encoding : utf-8 -*-
class Bs::SentMessages < ActiveRecord::Base
  self.table_name  = 'sms.sent_messages'

  attribute :sent_at, :datetime
end
