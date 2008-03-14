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

require 'rexml/document'
require 'net/http'
require 'uri'
include REXML

module ShippingCalc

  # This API is based on version 03 of the Freight Quote's (FQ) connection test,
  # release on 2007 (and still used on 2008). When you first create the
  # account you'll receive a test account that works with your username and
  # password. After having a stable system you should e-mail FQ asking for a
  # production key to the servers. If you want to test with a generic
  # username and password you can use: "xmltest@FreightQuote.com" : "XML",
  # but this won't give you access to all the debugging info. associated with
  # your account.
  class FreightQuote

    # Obtains a shipping quote from FQ's website.
    # <tt>params</tt> is a hash with all the settings for the shipment. They
    # are:
    # 
    # :*api_email*:: API access email, provided by FQ.
    # :*api_password*:: API access password, provided by FQ.
    # :*from_zip*:: Sender's zip code.
    # :*to_zip*:: Recipient's zip code.
    # :*weight*:: Total weight of the order in lbs.
    # :*dimensions*:: Length, width and height of the shipment, described as
    # a string: "[Length]x[Width]x[Height]" (e.g. "23x32x15").
    # :*description*:: Optional - Description of the stuff that's being
    # shipped. Defaults to "NODESC".
    def quote(params)
      required_fields = [:api_email, :api_password, :to_zip, :from_zip,
                         :weight, :dimensions]

      raise ShippingCalcError.new("Nil parameters for FreightQuote quote.") if params.nil?
      raise ShippingCalcError.new("Invalid shipment dimensions") unless (params[:dimensions] =~ /\d+x\d+x\d+/)

      required_fields.each do |f|
        if params.has_key?(f) && !params[f].nil? # Cover all the mandatory fields
          next
        else
          raise ShippingCalcError.new("Required field \"#{f}\" not found.")
        end
      end

      params[:description] ||= "NODESC"

      @xml = xml = Document.new
      xml << XMLDecl.new("1.0' encoding='UTF-8")
      rate_estimate(params)
      request
    end

    private

    # Creates the XML for the request.
    def rate_estimate(params)
      root = Element.new("FREIGHTQUOTE")
      root.attributes["REQUEST"] = "QUOTE"
      root.attributes["EMAIL"] = params[:api_email]
      root.attributes["PASSWORD"] = params[:api_password]
      # We're only getting a quote, let's pretend the shipper's paying.
      root.attributes["BILLTO"] = "SHIPPER" 

      origin = Element.new("ORIGIN")
      orig_zip = Element.new("ZIPCODE")
      orig_zip.text = params[:to_zip]

      origin << orig_zip
      root << origin

      dest = Element.new("DESTINATION")
      dest_zip = Element.new("ZIPCODE")
      dest_zip.text = params[:from_zip]
      
      dest << dest_zip
      root << dest

      root << shipment_item(params[:weight], params[:dimensions], params[:description])
      @xml << root
    end

    # Sends the request to FQ's server.
    def request
      server = Net::HTTP.new("b2b.freightquote.com", 80)
      path = path = "/dll/fqxmlquoter.asp"
      data = @xml.to_s
      headers = { "Content-Type" => "text/xml"}
      resp = server.post(path, data, headers)
      price = parse_response(resp.body)
    end

    # Parses the server's response.
    def parse_response(xml)
      p xml
    end

    # Create a shipment item based on the weight, dimension and description.
    def shipment_item(weight_, dim, desc)
      raise ShippingCalcError.new("Invalid weight") if !(weight_ > 0)
      shipment = Element.new("SHIPMENT")
      weight = Element.new("WEIGHT")
      weight.text = weight_.to_s
      shipment << weight

      description = Element.new("PRODUCTDESC")
      description.text = desc
      shipment << description

      dimensions = Element.new("DIMENSIONS")
      d = dim.split("x")
      l = Element.new("LENGTH")
      w = Element.new("WIDHT")
      h = Element.new("HEIGHT")
      l.text = d[0]
      w.text = d[1]
      h.text = d[2]

      dimensions << l
      dimensions << w
      dimensions << h
      shipment << dimensions

      shipment
    end
  end
end
