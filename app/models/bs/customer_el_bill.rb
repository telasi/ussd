# -*- encoding : utf-8 -*-
class Bs::CustomerElBill < ActiveRecord::Base
  self.table_name  = 'bs.customer_el_bill'
  self.set_integer_columns :sms
end