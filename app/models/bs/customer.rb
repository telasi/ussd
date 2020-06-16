# -*- encoding : utf-8 -*-
class Bs::Customer < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  ACTIVE = 0
  INACTIVE = 1
  CLOSED = 2

  TELASI_WEB_SITE = 'www.telasi.ge'

  XXX = 'xxx-qs'

  self.table_name  = 'bs.customer'
  self.primary_key = :custkey

  scope :physical, -> { where("CUSTCATKEY NOT IN (4,5,6)") }

  has_many :faxes,          class_name: 'Bs::CustomerFax',   foreign_key: :custkey
  belongs_to :address,      class_name: 'Bs::Address',       foreign_key: :premisekey
  has_one    :taxid,        class_name: 'Bs::CustomerId',    foreign_key: :custkey
  belongs_to :send_address, class_name: 'Billing::Address',       foreign_key: :sendkey
  has_one  :trash_customer, class_name: 'Billing::TrashCustomer', foreign_key: :custkey
  has_one  :water_customer, class_name: 'Billing::WaterCustomer', foreign_key: :custkey
  has_many :accounts,       class_name: 'Bs::Account',       foreign_key: :custkey
  has_many :water_items,    -> { order 'year, month' }, class_name: 'Billing::WaterItem', foreign_key: :custkey
  has_many :item_bills,     -> { order 'itemkey' },     class_name: 'Billing::ItemBill',  foreign_key: :custkey
  has_many :customer_custs, class_name: 'Billing::CustomerCust',  foreign_key: :custkey
  has_one  :note,           class_name: 'Billing::Note',          foreign_key: :notekey
  belongs_to :category,     class_name: 'Billing::Custcateg',     foreign_key: :custcatkey
  belongs_to :activity,     class_name: 'Billing::Custcateg',     foreign_key: :activity

  def region; self.address.region end
  def water_balance; self.water_customer.new_balance rescue 0 end
  def current_water_balance; self.water_customer.curr_charge rescue 0 end
  def trash_balance; self.trash_customer.balance rescue 0 end
  def last_bill_date; self.item_bills.last.billdate end
  def last_bill_number; self.item_bills.last.billnumber end

  def status
    status = true
    reason = ''

    ch = Bs::CutHistory.where(custkey: self.custkey).where('OPER_DATE >= SYSDATE - 7').order('cr_key desc').first
    if ch && ch.oper_code == 0
     status = false
     reason = 'payment'
    end

    outage = Bs::OutageJournalCust.where(custkey_customer: self.custkey).open.accepted.first
    if outage.present?
    # if outage.present? && outage.detail.present?
    #   if outage.detail.enabled != 1 || outage.detail.on_time.blank?
         status = false
         reason = outage.detail.type_descr
       # end
    end

    return [status, reason]
  end

  def due_date
    due_date = ""
    bill_notif = Bs::CustomerBillNotification.where(accnumb: self.accnumb).first || Bs::CustomerBillNotificationPrev.where(accnumb: self.accnumb).first
    due_date = bill_notif.lastday if bill_notif.present?
    due_date
  end

  def abonent_type
    return 1 if [1, 7, 1111, 1112, 1113, 1120].include?(self.custcatkey)
    return 2
  end

  def deposit_customer
    Bs::DepositCustomer.where(custkey: self.custkey, status: 0).first
  end

  def deposit_amount
    if self.deposit_customer and self.deposit_customer.active?
      return self.deposit_customer.start_depozit_amount
    else
      return 0
    end
  end

  def cut_deadline
    unless @cut_deadline
      last = self.item_bills.last
      @cut_deadline = last.lastday if last
    end
    @cut_deadline
  end


  def pre_payment
    pre_payments.inject(0) do |sum, payment|
      sum += payment.amount
    end
  end


  def pre_payment_date
    pre_payments.order('paykey desc').first.try(:paydate)
  end


  def pre_trash_payment
    pre_trash_payments.inject(0) do |sum, payment|
      sum += payment.amount
    end
  end


  def pre_trash_payment_date
    pre_trash_payments.order('paykey desc').first.try(:paydate)
  end


  def pre_water_payment
    pre_water_payments.inject(0) do |sum, payment|
      sum += payment.amount
    end
  end


  def pre_water_payment_date
    pre_water_payments.order('paykey desc').first.try(:paydate)
  end


  def status_name
    case self.statuskey
    when ACTIVE   then I18n.t('models.bs.customer.statuses.active')
    when INACTIVE then I18n.t('models.bs.customer.statuses.inactive')
    when CLOSED   then I18n.t('models.bs.customer.statuses.closed')
    else '?'
    end
  end


  def balance_sms
    sms_text( true )
  end


  def deadline_sms
    sms_text( false )
  end


  def sms_text(include_credits)
    if include_credits || cut_candidate?
      deadline = self.cut_deadline
      telasi_debt = "თელასი #{number_with_precision self.payable_balance, precision: 2} L" if ( include_credits || cut_candidate_telasi? )
      trash_debt = "დასუფთავება #{number_with_precision self.payable_trash_balance, precision: 2} L" if ( include_credits || cut_candidate_trash? )
      water_debt = "წყალმომარაგება #{number_with_precision (self.payable_water_balance || 0), precision: 2} L" if ( include_credits || cut_candidate_water? )
      debts = [ telasi_debt, trash_debt, water_debt ].compact.join("\n")
      txt = "აბ.##{self.accnumb} დავალიანება:\n#{debts}.\nგადახდის ბოლო თარიღია #{deadline.strftime('%d.%m.%Y')} -mde\nSMS off 90033"
      txt.to_ka
    end
  end


  def payable_balance
    @payable_balance ||= self.balance + self.deposit_amount - self.pre_payment
  end


  def payable_water_balance
    @payable_water_balance ||= (self.current_water_balance || 0) - self.pre_water_payment
  end


  def payable_trash_balance
    trash_balance = self.trash_customer && self.trash_customer.balance
    @payable_trash_balance ||= (trash_balance || 0) - self.pre_trash_payment
  end


  def cut_candidate_water?
    payable_water_balance > 0.99
  end


  def cut_candidate_trash?
    payable_trash_balance > 0.99
  end


  def cut_candidate_telasi?
    payable_balance > 0.99
  end


  def cut_candidate?
    cut_candidate_telasi? || cut_candidate_trash? || cut_candidate_water?
  end


  def self.sms_candidates
    Billing::Customer.where('fax IS NOT NULL')
  end


  def to_s
    if self.commercial.present?
      a = "#{self.custname.to_ka} (#{self.commercial.to_ka})"
    else
      a = self.custname.to_ka
    end
    "#{self.accnumb.to_ka} -- #{a}"
  end

  def to_hash
    status, message = self.status
    {   subscriberID: self.accnumb,
        currentStatus: status ? 1 : -1,
        balance: (self.payable_balance * 100).to_i,
        dueDate:  self.due_date,
        message: message,
        address: self.address.region.address,
        phoneNumber: [ self.address.region.phone || '' ],
        webAddress: TELASI_WEB_SITE,
        mainNumber: self.fax,
        alternativeNumber: self.faxes.n_status.map{ |x| x.fax }
    }
  end

private

  def pre_payments
    Bs::Payment.where('paydate > ? AND custkey = ? AND status IN (0, 1)', 7.days.ago.to_date, self.custkey)
  end


  def pre_trash_payments
    Billing::TrashPayment.where('paydate>? AND custkey=? AND status IN (0, 1)', 7.days.ago.to_date, self.custkey)
  end


  def pre_water_payments
    Billing::WaterPayment.where('paydate>? AND custkey=? AND status IN (0, 1)', 7.days.ago.to_date, self.custkey)
  end

  def self.tps
    Billing::Customer.where('custcatkey = 4 and statuskey <> 2')
  end

end
