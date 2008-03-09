require File.dirname(__FILE__) + '/../test_helper'
require 'yaml'

include ShippingCalc

class DHLTest < Test::Unit::TestCase

  def setup
    auth_info = auth_info_from_file
    api_user = auth_info["api_user"]
    api_pwd = auth_info["api_password"]
    api_key = auth_info["shipping_key"]
    api_accnt_num = auth_info["account_num"]

    @opts = { 
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

    @d = DHL.new
  end

  def test_quote
    assert_in_delta "172.5", @d.quote(@opts), 5
  end

  def test_params_empty
    assert_raise NoMethodError do 
      @d.quote(nil)
    end
  end

  def test_not_enough_params
    @opts.delete(:weight)
    assert_raise ShippingCalcError do 
      @d.quote(@opts)
    end
  end

  def test_invalid_weight
    @opts[:weight] = -1
    assert_raise ShippingCalcError do 
      @d.quote(@opts)
    end
  end

  def test_invalid_zip_code
    @opts[:to_zip] = "10002"
    assert_raise ShippingCalcError do
      @d.quote(@opts)
    end
  end

  # Auth info is private, gotta load it this way.
  def auth_info_from_file
    info = YAML.load_file("/home/#{ENV["USER"]}/.dhl_info.yml")
  end

end
