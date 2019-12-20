class ServiceController < ApplicationController

 SMS_ON = 1
 SMS_OFF = 3
 COMPANY = 'GEOCELL'
 RECEIVER_MOBILE = '90033'
 LAST_MESSAGE = 'L'
 MESSAGE_STATUS = 'N'
 TELASI_WEB_SITE = 'www.telasi.ge'
  
 def getSubscriberByPhone
 	phoneNumber = @jsonBody["phoneNumber"]
 	customer = Bs::Customer.where(fax: phoneNumber).first
 	if customer.blank?
	  ceb = Bs::CustomerElBill.where(mobile: phoneNumber).first
	  customer = Bs::Customer.find(ceb.custkey) if ceb.present?
	end
	if customer.present?
	 	render json: { errorCode: 0,
					   SubscriberID: customer.accnumb,
					   currentStatus: customer.status[0] ? 1 : 0,
					   balance: customer.payable_balance }
	else
		render json: { errorCode: -1,
					   SubscriberID: "",
					   currentStatus: 0 }
	end
 end

 def sendDigitalReceipt
 	phoneNumber = @jsonBody["phoneNumber"]
 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	updateFaxAndSender(customer, phoneNumber)
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
 	end
 	


 	render json: { errorCode: 0 }
 end

 def removePhoneNumber
 	phoneNumber = @jsonBody["phoneNumber"]
 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	ceb = Bs::CustomerElBill.where(accnumb: subscriberID, mobile: phoneNumber).first
 	ceb.update_attributes!(sms: SMS_OFF) if ceb.present?
 end

 def getSubscriberContactPhones
 	subscriberID = @jsonBody["subscriberID"]
 	customer = Bs::Customer.where(accnumb: subscriberID).first
 	raise "Customer not found" if customer.blank?
 	render json: { errorCode: 0,
 				   mainNumber: customer.fax,
 				   alternativeNumber: Bs::CustomerElBill.where(accnumb: subscriberID).map{ |x| x.mobile }.join(',') }
 end

 private 

 def updateFaxAndSender(customer, phoneNumber)
 	Bs::Customer.transaction do 
	 	customer.fax = phoneNumber
	 	customer.save
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
	 	customer.fax = phoneNumber
	 	customer.save
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
  
end
