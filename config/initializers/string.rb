# -*- encoding : utf-8 -*-
class String

  def  to_ka 
     #self.tr("ÀÁÂÃÄÅÆÈÉÊËÌÍÏÐÑÒÓÔÖ×ØÙÚÛÜÝÞßàáãä","აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ")
      self.tr("ÀÁÂÃÄÅÆÈÉÊËÌÍÏÐÑÒÓÔÖ×ØÙÚÛÜÝÞßàáãä","აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ").force_encoding("UTF-8")
  end

  def  ka_str_to_bs
    self.tr("აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ", "ÀÁÂÃÄÅÆÈÉÊËÌÍÏÐÑÒÓÔÖ×ØÙÚÛÜÝÞßàáãä")
  end

  def  bs_str_to_en
     #self.tr("ÀÁÂÃÄÅÆÈÉÊËÌÍÏÐÑÒÓÔÖ×ØÙÚÛÜÝÞßàáãä","აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ")
      self.tr("ÀÁÂÃÄÅÆÈÉÊËÌÍÏÐÑÒÓÔÖ×ØÙÚÛÜÝÞßàáãä","abgdevzTiklmnopJrstufqRYSCcZwWxjh")
  end


end