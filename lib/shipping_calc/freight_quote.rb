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
  # password. 
  #
  # After having a stable system you should e-mail FQ asking for a
  # production key to the servers. If you want to test with a generic
  # username and password you can the user "xmltest@FreightQuote.com" with password "XML",
  # but this won't give you access to all the debugging info. associated with
  # your account (or so they say).
  class FreightQuote

    # Obtains some shipping quotes using freight carriers from FQ's site.
    # The return value is a hash like {carrier_name => rate} so you can see
    # all the available prices.
    # <tt>params</tt> is a hash with all the settings for the shipment. They
    # are:
    # 
    # :*api_email*:: API access email, provided by FQ.
    # :*api_password*:: API access password, provided by FQ.
    # :*from_zip*:: Sender's zip code.
    # :*to_zip*:: Recipient's zip code.
    # :*weight*:: Total weight of the order in lbs.
    # :*dimensions*:: _Optional_ - Length, width and height of the shipment, described as a string: "[Length]x[Width]x[Height]" (e.g. "23x32x15").
    # :*description*:: _Optional_ - Description of the stuff that's being shipped. Defaults to "NODESC".
    # :*class*:: _Optional_ - Freightquote's shipping class. Defaults to nil.
    # :*from_conditions*:: _Optional_ - String that indicates if the sending location is a residence ("RES"), a business with a forklift or dock ("BIZ_WITH") or a business without a forklift or dock ("BIZ_WITHOUT"). Defaults to "RES".
    # :*to_conditions*:: _Optional_ - String that indicates if the receiving location is a residence ("RES"), a business with a forklift or dock ("BIZ_WITH") or a business without a forklift or dock ("BIZ_WITHOUT"). Defaults to "RES".
    # :*liftgate*:: _Optional_ - A boolean indicating if a liftgate's required at the receiving location (API page 10). Defaults to false.
    # :*inside_delivery*:: _Optional_ - A boolean indicating if inside delivery's required at the receiving location (API page 10). Defaults to false.
    # *Note* Both dimensions or class are optional but one of them has to be there. If both parameters are filled then priority will be given to class.
    def quote(params)
      validate params
      params[:description] ||= "NODESC"
      params[:from_conditions] ||= "RES"
      params[:to_conditions] ||= "RES"

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

      root << destination(params[:from_zip], params[:from_conditions],
                     params[:liftgate], params[:inside_delivery]) 
      root << origin(params[:from_zip], params[:from_conditions])

      root << shipment_item(params[:weight], params[:dimensions],
      params[:description], params[:class])
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

    # Parses the server's response. Returns a hash with the carriers and
    # their rates.
    def parse_response(xml)
      quotes = { }
      doc = Document.new(xml)
      q = doc.elements.each("*/CARRIER") do |e| 
        name = e.elements["CARRIERNAME"].text
        rate = e.elements["RATE"].text
        quotes[name] = rate
      end
      quotes
    end

    # TODO Merge this method with destination's.
    def origin (zip, conditions)
      origin = Element.new("ORIGIN")
      orig_zip = Element.new("ZIPCODE")
      orig_zip.text = zip
      origin << orig_zip

      case conditions
      when "RES"
        residence = Element.new("RESIDENCE")
        residence.text = "TRUE"
        origin << residence
      when "BIZ_WITH"
        dock = Element.new("LOADINGDOCK")
        dock.text = "TRUE"
        origin << dock
      when "BIZ_WITHOUT"
        dock = Element.new("LOADINGDOCK")
        dock.text = "FALSE"
        origin << dock
      end

      origin
    end

    def destination(zip, conditions, liftgate, inside)
      dest = Element.new("DESTINATION")
      dest_zip = Element.new("ZIPCODE")
      dest_zip.text = zip
      dest << dest_zip

      case conditions
      when "RES"
        residence = Element.new("RESIDENCE")
        residence.text = "TRUE"
        dest << residence
      when "BIZ_WITH"
        dock = Element.new("LOADINGDOCK")
        dock.text = "TRUE"
        dest << dock
      when "BIZ_WITHOUT"
        dock = Element.new("LOADINGDOCK")
        dock.text = "FALSE"
        dest << dock
      end

      if !liftgate.nil? && liftgate
        liftgate = Element.new("LIFTGATEDELIVERY")
        liftgate.text = "TRUE"
        dest << liftgate
      end
      
      if !inside.nil? && inside
        inside = Element.new("INSIDEDELIVERY")
        inside.text = "TRUE"
        dest << inside
      end

      dest
    end

    # Create a shipment item based on the weight, dimension and description.
    def shipment_item(weight_, dim, desc, s_class = nil)
      raise ShippingCalcError.new("Invalid weight") if !(weight_ > 0)
      shipment = Element.new("SHIPMENT")
      weight = Element.new("WEIGHT")
      weight.text = weight_.to_s
      shipment << weight

      description = Element.new("PRODUCTDESC")
      description.text = desc
      shipment << description

      if s_class.nil?
        dimensions = Element.new("DIMENSIONS")
        d = dim.split("x")
        l = Element.new("LENGTH")
        w = Element.new("WIDTH")
        h = Element.new("HEIGHT")
        l.text = d[0]
        w.text = d[1]
        h.text = d[2]

        dimensions << l
        dimensions << w
        dimensions << h
        shipment << dimensions
      else
        ship_class = Element.new("CLASS")
        ship_class.text = s_class.to_s
        shipment << ship_class
      end

      pieces = Element.new("PIECES")
      pieces.text= "1"
      shipment << pieces

      shipment
    end

    def validate(params)
      required_fields = [:api_email, :api_password, :to_zip, :from_zip,
                         :weight]

      raise ShippingCalcError.new("Nil parameters for FreightQuote quote.") if params.nil?
      raise ShippingCalcError.new("Invalid shipment dimensions") unless
        ((params[:dimensions] =~ /\d+x\d+x\d+/) || (!params[:class].nil?))

      raise ShippingCalcError.new("Invalid receiving conditions") unless
        valid_conditions(params[:to_conditions]) 
      raise ShippingCalcError.new("Invalid shipping conditions") unless
        valid_conditions(params[:from_conditions]) 

      if !(params[:liftgate].nil?)
        raise ShippingCalcError.new("Invalid liftgate option, only boolean values.") unless
          (params[:liftgate].class == TrueClass || params[:liftgate].class == FalseClass)
      end

      if !(params[:inside_delivery].nil?)
        raise ShippingCalcError.new("Invalid inside delivery option, only boolean values.") unless
          (params[:inside_delivery].class == TrueClass || params[:inside_delivery].class == FalseClass)
      end

      required_fields.each do |f|
        if params.has_key?(f) && !params[f].nil? # Cover all the mandatory fields
          next
        else
          raise ShippingCalcError.new("Required field \"#{f}\" not found.")
        end
      end

    end

    def valid_conditions(cond)
      cond.nil? || ((cond =~ /^(BIZ_WITH|RES|BIZ_WITHOUT)$/) == 0)
    end
  end
end
