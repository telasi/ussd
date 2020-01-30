class ServiceController < ApplicationController

 SMS_ON = 1
 SMS_OFF = 3
 COMPANY = 'GEOCELL'
 RECEIVER_MOBILE = '90033'
 LAST_MESSAGE = 'L'
 MESSAGE_STATUS = 'N'
 TELASI_WEB_SITE = 'www.telasi.ge'
  
 def getSubscriberByPhone
 	phoneNumber = params["phoneNumber"]
 	raise Error::SubscriberNotFoundError.new if phoneNumber.blank?
 	phoneNumber = phoneNumber.delete(' ')
 	customers = Bs::Customer.where(fax: phoneNumber)
 	customer_faxs = Bs::CustomerFax.where('SUBSTR(fax, -9, 9) = ?', phoneNumber)
	if customers.present? || customer_faxs.present?
		renderedJson = { subscribers: [] }
		customers.each do |customer|
			renderedJson[:subscribers] << customer_hash(customer)
		end
		customer_faxs.each do |customer|
			renderedJson[:subscribers] << customer_hash(customer)
		end
	 	render json: renderedJson
	else
		raise Error::SubscriberNotFoundError.new
	end
 end

 def sendDigitalReceipt
 	phoneNumber = @jsonBody["phoneNumber"]
 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	updateFaxAndSender(customer, phoneNumber)
 	ActiveRecord::Base.connection.execute("BEGIN sms.sms_pack.send__bill_notif_sms_proc_ussd('#{subscriberID}', '#{phoneNumber}'); end;")
 	render json: { errorCode: 0 }
 end

 def getServiceSuspendReason
 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	render json: { subscriberID: subscriberID,
				   message: customer.status[1] }
 end

 def resendLastSMS
 	phoneNumber = @jsonBody["phoneNumber"]
 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	updateFaxAndSendLast(customer, phoneNumber)
 	render json: { errorCode: 0 }
 end

 def getCompanyContacts
 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	render json: { address: 	customer.address.region.address,
 				   phoneNumber: customer.address.region.phone,
 				   webAddress:  TELASI_WEB_SITE } 
 end

 def addNewSubscriber
 	phoneNumber = @jsonBody["phoneNumber"]
 	subscriberID = @jsonBody["subscriberID"]
 	personalID = @jsonBody["personalID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	if customer.blank?
 		render json: { errorCode: -1,
			   	       errorMessage: "" }
 	elsif Bs::CustomerId.where(custkey: customer.custkey, customer_id: personalID).blank?
 		render json: { errorCode: -2,
			   	       errorMessage: "" }
 	else
 		fax = Bs::CustomerFax.where('SUBSTR(fax, -9, 9) = ?', phoneNumber)
 		Bs::CustomerFax.new(custkey:    customer.custkey,
 							fax:        "995#{phoneNumber}",
 							parent_fax: customer.fax ).save if fax.blank?

 		Bs::CustomerCandidate.new(accnumb:    customer.accnumb, 
								  phone:      phoneNumber,
								  fax:        customer.fax,
								  status:  	  'U',
								  enter_date: Time.now).save
 		render json: { errorCode: 0,
			   	       errorMessage: "" }
 	end
 end

 def removePhoneNumber
 	phoneNumber = @jsonBody["phoneNumber"]
 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	customerFax = CustomerFax.where('SUBSTR(fax, -9, 9) = ?', phoneNumber).first
	customerFax.update_attributes!(message_status: 'C') if customer_fax.present?
 	ceb = Bs::CustomerElBill.where(accnumb: subscriberID, mobile: phoneNumber).first
 	ceb.update_attributes!(sms: SMS_OFF) if ceb.present?
 end

 def getSubscriberContactPhones
 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	render json: { errorCode: 0,
 				   mainNumber: customer.fax,
 				   alternativeNumber: Bs::CustomerFax.where(parent_fax: customer.fax).map{ |x| x.fax }.join(',') }
 end

 private 

 def customer_hash(customer)
 	status, message = customer.status
	{ 	SubscriberID: customer.accnumb,
	    currentStatus: status ? 1 : -1,
	    balance: customer.payable_balance,
	    message: message,
	    address: customer.address.region.address,
	    phoneNumber: [ customer.address.region.phone ],
	    webAddress: TELASI_WEB_SITE,
	    mainNumber: customer.fax,
	    alternativeNumber: Bs::CustomerFax.where(parent_fax: customer.fax).map{ |x| x.fax }
	}
 end

 def updateFaxAndSender(customer, phoneNumber)
 	Bs::Customer.transaction do 
 		updateFax(customer, phoneNumber)
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
	 	sent_message = Bs::SentMessages.where(receiver_mobile: phoneNumber).first
	 	raise 'No message' if sent_message.blank?
	 	sms = Bs::SmsMessages.new(company:  	   COMPANY, 
		 						  sender_mobile:   phoneNumber,
		 						  text: 		   sent_message.text,
		 						  receiver_mobile: RECEIVER_MOBILE,
		 						  message_type:    LAST_MESSAGE, 
		 						  message_status:  MESSAGE_STATUS )
	 	sms.save
 	end
 end

 def updateFax(customer, phoneNumber)
 	customer.fax = phoneNumber
	customer.save

	Bs::CustomerCandidate.new(accnumb:    customer.accnumb, 
							  phone:      phoneNumber,
							  fax:        customer.fax,
							  status:  	  'U',
							  enter_date: Time.now).save
 end
  
end
