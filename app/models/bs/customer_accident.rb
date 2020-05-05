# -*- encoding : utf-8 -*-
class Bs::CustomerAccident < ActiveRecord::Base
  self.table_name  = 'bs.customer_accident'

  attribute :accident_date, :datetime
end
