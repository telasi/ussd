# -*- encoding : utf-8 -*-
class Bs::OutageJournal < ActiveRecord::Base
  self.table_name  = 'bacho.outage_journal'
  self.primary_key = :id

  scope :ki_ara, -> { where("IS_GIS IN ('ki', 'ara')") }
end