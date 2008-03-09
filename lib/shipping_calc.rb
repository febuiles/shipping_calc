$:.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'rexml/document'
require 'net/http'
require 'net/https'
require 'uri'

require 'shipping_calc/base'
require 'shipping_calc/dhl'

module ShippingCalc
  class ShippingCalcError < StandardError
  end

  VERSION = "0.0.1"
  
end
  

