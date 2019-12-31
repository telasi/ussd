# -*- encoding : utf-8 -*-
class Bs::CustomerId < ActiveRecord::Base
  self.table_name  = 'bs.cust_identity'

  belongs_to :customer, class_name: 'Bs::Customer', foreign_key: :custkey
end
