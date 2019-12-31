# -*- encoding : utf-8 -*-
class Bs::DepositCustomer < ActiveRecord::Base
  self.establish_connection :bs

  self.table_name  = 'bs.zdepozit_cust'
  self.primary_key = :custkey

  attribute :status, :integer

  def active?; self.status == 0 end
end