require 'rubygems'
require 'shipping_calc'
require 'yaml'
include ShippingCalc

# This example requires you to have a .dhl_info.yml file in your home dir to
# gather the login data. Check the Test secion in README.txt for more information.

auth_info = YAML.load_file("/home/#{ENV["USER"]}/.dhl_info.yml")

api_user = auth_info["api_user"]
api_pwd = auth_info["api_password"]
api_key = auth_info["shipping_key"]
api_accnt_num = auth_info["account_num"]

opts = { 
  :api_user => api_user,
  :api_password => api_pwd,
  :shipping_key => api_key,
  :account_num => api_accnt_num,
  :date => Time.now,
  :service_code => "E", # check the docs to find out what this means
  :shipment_code => "P", # check the docs to find out what this means
  :weight => 34, # weight in lbs
  :to_zip => 10001,
  :to_state => "NY" 
}

d = DHL.new
q = d.quote(opts)
puts "Quote: " << q.to_s << "\n"
