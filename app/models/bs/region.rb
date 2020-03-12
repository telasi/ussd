# -*- encoding : utf-8 -*-
class Bs::Region < ActiveRecord::Base
  self.table_name  = 'bs.region'
  self.primary_key = :regionkey

  def self.valid; Bs::Region.where("REGTPKEY = 2 and REGIONKEY not in (32,111,36,444,555,888,999) and REGIONNAME not like '%/%'"); end

  def address
    location = self.location
    if location
      a = self.location.split('T')[0]
      a && a.bs_str_to_en.gsub('N', '№').gsub(',', ', ').gsub('.', '. ')
    end
  end

  def phone
    location = self.location
    if location
      p = self.location.split('T')[1]
      p && p.bs_str_to_en.gsub(',', ', ')
    end
  end

  def to_s
    self.regionname
  end

  def region_config
    Billing::RegionConfig.where(regionkey: self.regionkey).first
  end
end
