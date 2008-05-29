require 'rubygems'
require 'shipping_calc'
require 'yaml'
include ShippingCalc

opts = { 
  :api_email => "xmltest@FreightQuote.com",
  :api_password => "XML",
  :from_zip => 75042,
  :to_zip => 75042,
  :weight => 105,
  :class => 92.5,
  :to_conditions => "BIZ_WITHOUT"
}

f = FreightQuote.new
quotes = f.quote(opts)
p quotes
quotes.each do |k,v|
  p k + " - " + v
end



