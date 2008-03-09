require 'rexml/document'
require 'net/http'
require 'net/https'
require 'uri'


require 'shipping_calc/base'
require 'shipping_calc/dhl'

module ShippingCalc
  class ShippingCalcError < StandardError
  end
end
include ShippingCalc



opts = {
  :api_user => "PRINT_4126", 
  :api_password => "6296G82KU9",
  :shipping_key => "54233F2B2C4E5D41455B56545752305043485142445A535F54",
  :account_num => "783055820",
  :date => "2008-03-10",
  :service_code => "E",
  :shipment_code => "P",
  :weight => 34,
  :to_zip => 10001,
  :to_state => "NY"
}

d = DHL.new
a = d.quote(opts)
p a


