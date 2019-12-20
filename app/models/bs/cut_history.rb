# -*- encoding : utf-8 -*-
class Bs::CutHistory < ActiveRecord::Base
  self.establish_connection :report_bs

  self.table_name  = 'bs.cut_history'
  self.set_integer_columns :mark_code, :oper_code, :mark_code_insp, :upload_status, :upload_numb
end
