class ServiceController < ApplicationController

 SMS_ON = 1
 SMS_OFF = 3
 COMPANY = 'GEOCELL'
 RECEIVER_MOBILE = '90033'
 LAST_MESSAGE = 'L'
 MESSAGE_STATUS = 'N'
 TELASI_WEB_SITE = 'www.telasi.ge'
  
 def getSubscriberByPhone
 	phoneNumber = params["phoneNumber"] || ''
 	raise Error::SubscriberNotFoundError.new unless valid?(phoneNumber)
 	customers = Bs::Customer.where(fax: phoneNumber)
 	customer_faxs = Bs::CustomerFax.where('SUBSTR(parent_fax, -9, 9) = ?', phoneNumber)
	if customers.present? || customer_faxs.present?
		renderedJson = { subscribers: [] }
		customers.each do |customer|
			renderedJson[:subscribers] << customer_hash(customer)
		end
		customer_faxs.each do |customer_fax|
			customer = Bs::Customer.find(customer_fax.custkey)
			next if renderedJson[:subscribers].find{ |x| x[:subscriberID] == customer.accnumb }.present?
			renderedJson[:subscribers] << customer_hash(customer)
		end
	 	render json: renderedJson
	else
		raise Error::SubscriberNotFoundError.new
	end
 end

 def sendDigitalReceipt
 	phoneNumber = @jsonBody["phoneNumber"]
 	raise Error::SubscriberNotFoundError.new unless valid?(phoneNumber)

 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	updateFaxAndSender(customer, phoneNumber)
 	ActiveRecord::Base.connection.execute("BEGIN sms.sms_pack.send__bill_notif_sms_proc_ussd('#{subscriberID}', '#{phoneNumber}'); end;")
 	render json: { errorCode: 0 }
 end

 def getServiceSuspendReason
 	subscriberID = @jsonBody["subscriberID"]
 	raise Error::SubscriberNotFoundError.new unless in_subscriber_whitelist(subscriberID)

 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	render json: { subscriberID: subscriberID,
				   message: customer.status[1] }
 end

 def resendLastSMS
 	phoneNumber = @jsonBody["phoneNumber"]
 	raise Error::SubscriberNotFoundError.new unless valid?(phoneNumber)

 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	updateFaxAndSendLast(customer, phoneNumber)
 	render json: { errorCode: 0 }
 end

 def getCompanyContacts
 	subscriberID = @jsonBody["subscriberID"]
 	raise Error::SubscriberNotFoundError.new unless in_subscriber_whitelist(subscriberID)

 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	render json: { address: 	customer.address.region.address,
 				   phoneNumber: customer.address.region.phone,
 				   webAddress:  TELASI_WEB_SITE } 
 end

 def addNewSubscriber
 	phoneNumber = @jsonBody["phoneNumber"]
	raise Error::SubscriberNotFoundError.new unless valid?(phoneNumber)

 	subscriberID = @jsonBody["subscriberID"]
 	personalID = @jsonBody["personalID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	if customer.blank?
 		render json: { errorCode: -1,
			   	       errorMessage: "" }
 	# elsif Bs::CustomerId.where(custkey: customer.custkey, customer_id: personalID).blank?
 	# 	render json: { errorCode: -2,
		# 	   	       errorMessage: "" }
 	else
 		Bs::CustomerCandidate.new(accnumb:    customer.accnumb, 
								  phone:      phoneNumber,
								  taxid:      personalID,
								  fax:        customer.fax,
								  status:  	  'A',
								  enter_date: Time.now).save

 		# fax = Bs::CustomerFax.where('SUBSTR(fax, -9, 9) = ?', phoneNumber)
 		# Bs::CustomerFax.new(custkey:    customer.custkey,
 		# 					fax:        "995#{phoneNumber}",
 		# 					parent_fax: customer.fax ).save if fax.blank?

 		customer.update_attributes!(fax: phoneNumber)
 		
 		render json: { errorCode: 0,
			   	       errorMessage: "" }
 	end
 end

 def removePhoneNumber
 	phoneNumber = @jsonBody["phoneNumber"][-9..-1]
	#raise Error::SubscriberNotFoundError.new unless valid?(phoneNumber)

 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	customerFax = Bs::CustomerFax.where('SUBSTR(fax, -9, 9) = ? and CUSTKEY = ?', phoneNumber, customer.custkey).first
	customerFax.update_attributes!(message_status: 'C') if customerFax.present?
 	ceb = Bs::CustomerElBill.where(accnumb: subscriberID, mobile: phoneNumber).first
 	ceb.update_attributes!(sms: SMS_OFF) if ceb.present?
 	cc = Bs::CustomerCandidate.where(accnumb: subscriberID).first
 	cc.update_attributes!(status: 'D') if cc.present?
 end

 def getSubscriberContactPhones
 	subscriberID = @jsonBody["subscriberID"]
 	raise Error::SubscriberNotFoundError.new unless in_subscriber_whitelist(subscriberID)

 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	render json: { errorCode: 0,
 				   mainNumber: customer.fax,
 				   alternativeNumber: Bs::CustomerFax.where(parent_fax: customer.fax).map{ |x| x.fax }.join(',') }
 end


 def getMeterList
 	subscriberID = @jsonBody["subscriberID"]
 	raise Error::SubscriberNotFoundError.new unless in_subscriber_whitelist(subscriberID)

 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?

 	render json: { meterList: Bs::Account.where(custkey: customer.custkey).map{ |x| x.mtnumb }.to_a,
 				   errorCode: 0 }
 end

 def addReading
 	phoneNumber = @jsonBody["phoneNumber"]
	raise Error::SubscriberNotFoundError.new unless valid?(phoneNumber)

 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?

 	meterID = @jsonBody["meterID"]
 	account = Bs::Account.where(custkey: customer.custkey, mtnumb: meterID).first
 	raise "Wrong meter" if account.blank?

 	cc = Bs::CustomerCandidate.where(accnumb: customer.accnumb, enter_date: Date.today, acckey: account.acckey).first
 	if cc.present?
 		cc.update_attributes!(mtnumb: meterID, reading: @jsonBody["reading"])
 	else
 	    cc = Bs::CustomerCandidate.where(accnumb: customer.accnumb, 
 	   									 enter_date: Date.today,
 	   									 acckey: nil).first || 
	 		 Bs::CustomerCandidate.new(  accnumb:    customer.accnumb, 
									     phone:      phoneNumber,
									     fax:        customer.fax,
									     status:  	 'U',
									     enter_date: Date.today)
	   debugger
	   cc.save
 	end
 	render json: { errorCode: 0 }
 end

 def addAccident
 	phoneNumber = @jsonBody["phoneNumber"]
 	raise Error::SubscriberNotFoundError.new unless valid?(phoneNumber)

 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?

 	address = @jsonBody["address"].strip
 	accidentDate = @jsonBody["accidentDate"] || Time.now.to_s

 	raise 'Error' unless Bs::CustomerAccident.new(accnumb: subscriberID, phone: phoneNumber, address: address, accident_date: accidentDate, status: 'N').save

 	render json: { errorCode: 0 }
 end

 private 

 def valid?(phoneNumber)
 	phoneNumber = phoneNumber.delete(' ')
 	return false if phoneNumber.blank?
 #	return false if in_blacklist(phoneNumber)
 #	return true  if in_whitelist(phoneNumber)
 	return true
 end

 def in_whitelist(phoneNumber)
 	[
 	'577783120',
 	'593721880', 
 	'599294156',
 	'593666598',
 	'599552440',
 	'551234234',
 	'599482211', # ირინა ჯაფარიძე
 	'577787855',
 	'599906494', # ირმა პოლშინა 
 	'599509707', # მარიამ აზნიაშვილი
 	'599915333', # ლელა ღვალაძე
 	'568088546', # მზია წიკლაური
 	'593269094'  # მზეთია ნოზაძე
 	].include?(phoneNumber)
 end

 def in_blacklist(phoneNumber)
 	false
 end

 def in_subscriber_whitelist(subscriber)
 	customer = Bs::Customer.where(accnumb: subscriber).first
 	customer.present? && customer.fax.present? && in_whitelist(customer.fax)
 end

 def customer_hash(customer)
 	due_date = ""
 	bill_notif = Bs::CustomerBillNotification.where(accnumb: customer.accnumb).first
 	due_date = bill_notif.lastday if bill_notif.present?
 	status, message = customer.status
	{ 	subscriberID: customer.accnumb,
	    currentStatus: status ? 1 : -1,
	    balance: (customer.payable_balance * -100).to_i,
	    dueDate:  due_date,
	    message: message,
	    address: customer.address.region.address,
	    phoneNumber: [ customer.address.region.phone || '' ],
	    webAddress: TELASI_WEB_SITE,
	    mainNumber: customer.fax,
	    alternativeNumber: Bs::CustomerFax.where(parent_fax: customer.fax).map{ |x| x.fax }
	}
 end

 def updateFaxAndSender(customer, phoneNumber)
 	Bs::Customer.transaction do 
 		# updateFax(customer, phoneNumber)
	 	ceb = Bs::CustomerElBill.where(accnumb: customer.accnumb).first || Bs::CustomerElBill.new(accnumb: customer.accnumb)
	 	ceb.custname 	= customer.custname
	 	ceb.custname_en = customer.custname
	 	ceb.enter_date 	= Time.now
	 	ceb.custkey 	= customer.custkey
	 	ceb.mobile 		= customer.fax
	 	ceb.acckey 		= customer.accounts.first.acckey
	 	ceb.email_name 	= customer.email
	 	ceb.sms 		= SMS_ON
	 	ceb.save
 	end
 end

 def updateFaxAndSendLast(customer, phoneNumber)
 	Bs::Customer.transaction do 
 		# updateFax(customer, phoneNumber)
 		mobile = "995#{phoneNumber}"
	 	# sent_message = Bs::SentMessages.where(receiver_mobile: mobile).first
	 	# if sent_message.blank?
	 	#   sent_message = Bs::SentMessagesArch.where(receiver_mobile: mobile).first
	 	# end
	 	# raise 'No message' if sent_message.blank?
	 	sms = Bs::SmsMessages.new(company:  	   COMPANY, 
		 						  sender_mobile:   mobile,
		 						  text: 		   '111',
		 						  receiver_mobile: RECEIVER_MOBILE,
		 						  # message_type:    LAST_MESSAGE, 
		 						  message_status:  MESSAGE_STATUS )
	 	sms.save
 	end
 end

 def updateFax(customer, phoneNumber)
 	customer.fax = phoneNumber
	customer.save

	# Bs::CustomerCandidate.new(accnumb:    customer.accnumb, 
	# 						  phone:      phoneNumber,
	# 						  fax:        customer.fax,
	# 						  status:  	  'U',
	# 						  enter_date: Time.now).save
 end
  
end
