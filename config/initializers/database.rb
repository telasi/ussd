# -*- encoding : utf-8 -*-

# BS server
Bs::OutageJournalCust.establish_connection :prod_bs
Bs::OutageJournalDet.establish_connection :prod_bs

Bs::Customer.establish_connection :bs
Bs::Payment.establish_connection :bs
Bs::CustomerFax.establish_connection :bs
Bs::SmsMessages.establish_connection :bs
Bs::CustomerElBill.establish_connection :bs
Bs::CustomerId.establish_connection :bs

Bs::CutHistory.establish_connection :report_bs