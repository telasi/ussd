# -*- encoding : utf-8 -*-
class Bs::Payment < ActiveRecord::Base
  #self.establish_connection :bs
  
  self.table_name  = 'payments.payment'
  self.primary_key = :paykey
  self.sequence_name = 'payments.payments_seq'

  attribute :status, :integer

  belongs_to :customer, class_name: 'Bs::Customer', foreign_key: :custkey
end
