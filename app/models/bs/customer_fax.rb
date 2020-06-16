# -*- encoding : utf-8 -*-
class Bs::CustomerFax < ActiveRecord::Base
  self.table_name  = 'bs.customer_fax'
  self.primary_key = :id

  MESSAGE_STATUS = 'N'

  scope :n_status, -> { where(message_status: MESSAGE_STATUS) }

  belongs_to :customer, class_name: 'Bs::Customer', foreign_key: :custkey
end
