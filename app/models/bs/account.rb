# -*- encoding : utf-8 -*-
class Bs::Account < ActiveRecord::Base
  TYPE_SUBSTATION = 1
  TYPE_FEEDER = 2
  TYPE_TRANSF = 3
  TYPE_METER  = 4

  self.table_name  = 'bs.account'
  self.primary_key = :acckey
  belongs_to :customer,      class_name: 'Bs::Customer',      foreign_key: :custkey
  belongs_to :address,       class_name: 'Billing::Address',       foreign_key: :premisekey
  belongs_to :meter_type,    class_name: 'Billing::MeterType',     foreign_key: :mttpkey
  has_one    :note,          class_name: 'Billing::Note',          foreign_key: :notekey
  has_many   :tariffs,       -> { order 'acctarkey' }, class_name: 'Billing::AccountTariff', foreign_key: :acckey
  has_one    :route_account, class_name: 'Billing::RouteAccount',  foreign_key: :acckey

  def status; self.statuskey == 0 ? 'აქტიური' : 'გაუქმებული' end
  def to_s; self.accid end
end
