# Copyright (c) 2008 Federico Builes

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

$:.unshift(File.dirname(__FILE__))

require 'rubygems'
require File.dirname(__FILE__) + "/shipping_calc/dhl"
require File.dirname(__FILE__) + "/shipping_calc/freight_quote"
module ShippingCalc

  VERSION = "0.1.7" 

  US_STATES =  ['AK', 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DC',
               'DE', 'FL', 'GA', 'HI', 'IA', 'ID', 'IL', 'IN',
               'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN',
               'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ',
               'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'RI',
               'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VT', 'WA',
               'WI', 'WV'] 


  class ShippingCalcError < StandardError
  end

end
