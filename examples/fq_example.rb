require 'rubygems'
require 'shipping_calc'
require 'yaml'
include ShippingCalc

opts = { 
  :api_email => "xmltest@FreightQuote.com",
  :api_password => "XML",
  :from_zip => 75042,
  :to_zip => 33166,
  :weight => 5,
  :dimensions => "1x1x1"
  :to_conditions => "BIZ_WITHOUT"
}

f = FreightQuote.new
quotes = f.quote(opts)
quotes.each do |k,v|
  p k + " - " + v
end


