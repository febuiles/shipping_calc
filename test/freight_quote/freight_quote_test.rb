require File.dirname(__FILE__) + '/../test_helper'
require 'yaml'

include ShippingCalc

class FreightQuoteTest < Test::Unit::TestCase

  def setup
    @opts = { 
      :api_email => "xmltest@FreightQuote.com",
      :api_password => "XML",
      :from_zip => 75042,
      :to_zip => 33166,
      :weight => 150,
      :dimensions => "12x23x12"
    }

  end
  
  def test_invalid_params
    f = FreightQuote.new
    assert_raise ShippingCalcError do 
      f.quote(nil)
    end
  end

  def test_quote_with_class
    @opts[:class] = 92.5
    @opts[:dimensions] = nil
    f = FreightQuote.new
    q = f.quote(@opts)
    assert q.size > 0
  end

  def test_invalid_dimension
    @opts[:dimensions] = "12x3"
    f = FreightQuote.new
    assert_raise ShippingCalcError do
      f.quote(@opts)
    end
  end

  def test_valid_quote
    f = FreightQuote.new
    quotes = f.quote(@opts)
    assert quotes.length > 0
  end
end
