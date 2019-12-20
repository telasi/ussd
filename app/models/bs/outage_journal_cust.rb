# -*- encoding : utf-8 -*-
class Bs::OutageJournalCust < ActiveRecord::Base
  self.table_name  = 'bacho.outage_journal_cust'
  self.primary_key = :custkey_customer

  belongs_to :detail, class_name: 'Bs::OutageJournalDet', foreign_key: :journal_det_id
end
