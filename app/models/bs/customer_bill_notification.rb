# -*- encoding : utf-8 -*-
class Bs::CustomerBillNotification < ActiveRecord::Base
  self.table_name  = 'bs.cust_bill_notification'
  self.primary_key = :id
end
