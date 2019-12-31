# -*- encoding : utf-8 -*-
class Bs::CutHistory < ActiveRecord::Base
  self.establish_connection :report_bs

  self.table_name  = 'bs.cut_history'

  attribute :mark_code, :integer
  attribute :oper_code, :integer
  attribute :mark_code_insp, :integer
  attribute :upload_status, :integer
  attribute :upload_numb, :integer
end
