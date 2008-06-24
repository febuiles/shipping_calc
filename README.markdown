ShippingCalc
============

* http://github.com/febuiles/shipping_calc/
* mailto:federico.builes@gmail.com

DESCRIPTION:
-----------

Shipping Calculator written in Ruby to get quick quotes from DHL and Freight Carriers.
We hope to support FedEx and UPS in a near future.	

FEATURES/PROBLEMS:
-----------------
- Current version only supports DHL and FreightQuote

SYNOPSIS:
--------
You can find an example of each carrier's API under the /examples directory.

A simple DHL example:

	require 'rubygems'
	require 'shipping_calc'

	include ShippingCalc

	opts = {
	  :api_user => "your_user", 
	  :api_password => "your_pwd",
	  :shipping_key => "your_key",
	  :account_num => "your_accnt",
	  :date => Time.now, 
	  :service_code => "E", # check the DHL docs to find out what this means
	  :shipment_code => "P", # check the DHL docs to find out what this means
	  :weight => 34, # weight in lbs
	  :to_zip => 10001,
	  :to_state => "NY"
	}

	d = DHL.new
	q = d.quote(opts)
	puts q

REQUIREMENTS:
---------------
* You must obtain all the DHL ShipIt data (user, password, key and account) from http://www.dhl-usa.com/TechTools/detail/TTDetail.asp?nav=TechnologyTools/Shipping/OwnSoln

INSTALL:
-------
* sudo gem install shipping-calc

TEST:
-----
To run the DHL tests you'll need to have a .dhl_info.yml file in your home directory with your auth info like this: 
    ~/.dhl_info.yml

    api_user: your_user
    api_password: your_password
    shipping_key: your_key
    account_num: your_accnt_num

This is necessary only for the tests and it'll be ignored for the actual
usage of the the library. 

LICENSE:
-------
Copyright (c) 2008 Federico Builes

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
