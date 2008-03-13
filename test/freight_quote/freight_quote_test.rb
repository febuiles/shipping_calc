require File.dirname(__FILE__) + '/../test_helper'
require 'yaml'

include ShippingCalc

class FreightQuoteTest < Test::Unit::TestCase

  def setup
    @opts = { 
      :api_email => "fake",
      :api_password => "fake",
      :from_zip => 23422,
      :to_zip => 43243,
      :weight => 150,
      :dimensions => "12x23x12"
    }

  end
  
  def test_invalid_params
    assert_raise ShippingCalcError do 
      f = FreightQuote.quote(nil)
    end
  end

  def test_invalid_dimension
    @opts[:dimensions] = "12x3"
    assert_raise ShippingCalcError do
      FreightQuote.quote(@opts)
    end
  end
end
