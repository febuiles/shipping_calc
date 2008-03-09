require 'rexml/document'
require 'net/http'
require 'net/https'
require 'uri'
include REXML

module ShippingCalc

  # Current version on their website is 1.0 and can be found in:
  # https://eCommerce.airborne.com/ApiLandingTest.asp . To get full access to
  # all their stuff you have to make sure they certify your application
  # against their live platform tests. The test bed should be enough to get
  # simple calculations.
  # Currently, only shipments made inside the US are available.
  class DHL < Base

    # Obtains an estimate quote from the DHL site. 
    # <tt>params</tt> is a hash with all the settings for the shipment. They are:
    #
    # :*api_user*:: API access username, provided by DHL.
    # :*api_password*:: API access password, provided by DHL.
    # :*shipping_key*:: API shipping key, provided by DHL.
    # :*account_num*:: Account number, provided by DHL.
    # :*date*:: Date for the shipping in format YYYY-MM-DD (defaults to Time.now).
    # :*service_code*:: Service code defined in Rate Estimate Specification(E, N, S, G). 1030 and SAT are not supported yet. Defaults to G (ground service).
    # :*shipment_code*:: ShipmentType code defined in the Rate Estimate Specification. "P" for Package or "L" for Letter. Defaults to "P".
    # :*weight*:: Order's weight. If the shipment code is a "L" (letter) then the weight will be 0.
    # :*to_zip*:: Recipient's zip code.
    # :*to_country*:: Recipient's country. Not used, currently DHL only supports US.
    # :*to_state*:: Recipient's state.

    def quote(params)
      @xml = xml = Document.new
      xml << XMLDecl.new("1.0' encoding='UTF-8")
      raise ShippingCalcError.new("Missing shipping parameters") unless params.keys.length == 10
      auth(params[:api_user], params[:api_password])
      rate_estimate(params)
      request
    end

    private 
    # DHL gets the quotes in 2 steps, the first one is authentication. This
    # generates the XML for that.
    def auth(api_user, api_password)
      ecomm = Element.new "eCommerce"
      ecomm.attributes["action"] = "Request"
      ecomm.attributes["version"] = "1.1"

      user = Element.new "Requestor"
      u_id = Element.new "ID"
      u_id.text = api_user 

      u_pwd = Element.new "Password"
      u_pwd.text = api_password 

      user << u_id
      user << u_pwd

      ecomm << user
      @xml << ecomm
    end

    # After having the auth message ready, we create the RateEstimate request.
    #     shipping_key: API shipping key, provided by DHL.
    #     account_num: Account number, provided by DHL.
    #     date: Date for the shipping in format YYYY-MM-DD (defaults to
    #     Time.now).
    #     service_code: Service code defined in Rate Estimate Specification
    #     (E, N, S, G). 1030 and SAT are not supported yet. Defaults to G
    #     (ground service).
    #     shipment_code: ShipmentType code defined in the Rate Estimate
    #     Specification. "P" for Package or "L" for Letter. Defaults to "P".
    #     weight: Order's weight. If the shipment code is a "L" (letter) then
    #     the weight will be 0.
    #     to_zip: Recipient's zip code.
    #     to_country: Recipient's country. Not used, currently DHL only supports US.
    #     to_state: Recipient's state.
    def rate_estimate(params)
      shipment = Element.new "Shipment"
      shipment.attributes["action"] = "RateEstimate"
      shipment.attributes["version"] = "1.0"

      credentials = Element.new "ShippingCredentials"
      key = Element.new "ShippingKey"
      key.text = params[:shipping_key] 

      account = Element.new "AccountNbr"
      account.text = params[:account_num] 

      credentials << key
      credentials << account
      shipment << credentials

      detail = Element.new "ShipmentDetail"
      date = Element.new "ShipDate"   

      date.text = date(params[:date])
      detail << date

      # TODO: Implement SAT and 1030 services
      service = Element.new "Service"
      s_code = Element.new "Code"
      s_code.text = service_code(params[:service_code])
      detail << service << s_code

      type = Element.new "ShipmentType"
      t_code = Element.new "Code"
      t_code.text = shipment_code(params[:shipment_code])
      detail << type << t_code

      weight = Element.new "Weight"
      weight.text = weight(params[:weight], params[:shipment_code])
      shipment << detail << weight

      billing = Element.new "Billing"
      b_party = Element.new "Party"
      p_code = Element.new "Code"
      # Since we're just doing some quick calulations we don't want to be
      # worrying about who's gonna send the package. Just make the calulations 
      # assuming the sender pays for the shipping.
      p_code.text = "S"
      shipment << billing << b_party << p_code

      receiver = Element.new "Receiver"
      r_addr = Element.new "Address"
      r_state = Element.new "State"
      r_country = Element.new "Country"
      r_zipcode = Element.new "PostalCode"

      r_state.text = state(params[:to_state])
      r_country.text = "US"
      r_zipcode.text = zip_code(params[:to_zip])

      r_addr << r_state
      r_addr << r_country
      r_addr << r_zipcode
      shipment << receiver << r_addr

      root = @xml.elements["eCommerce"]
      root.add shipment
    end

    # Sends the request to the web server and returns the response.
    def request
      server = Net::HTTP.new("eCommerce.airborne.com", 443)
      path = path = "/ApiLandingTest.asp"
      data = @xml.to_s
      headers = { "Content-Type" => "text/xml"}
      server.use_ssl = true
      resp = server.post(path, data, headers)
      price = parse_response(resp.body)
    end

    # Parses the server's response. Currently, it only returns the estimate
    # value of the shipping.
    def parse_response(resp)
      doc = Document.new(resp)
      result =  doc.elements["//Shipment/Result/Desc"].text 
      
      if result == "Shipment estimate successful."
        doc.elements["//Shipment/EstimateDetail/RateEstimate/TotalChargeEstimate"].text.to_f
      else
        raise ShippingCalcError.new("Error calculating shipping costs: + #{result}")
      end
    end

    def date(date)
      date =~ /\d{4}-\d{2}-\d{2}/ ? date : Time.now.strftime("%Y-%m-%d")
    end

    def shipment_code(code)
      ["P", "L"].include?(code) ? code : "P"
    end

    def service_code(code)
      ["E", "N", "S", "G"].include?(code) ? code : "G"
    end

    def weight(w, type)
      if type == "L"
        "0"
      else
        (w > 0 && w <= 150) ? w.to_s : (raise ShippingCalcError.new("Invalid weight - Must be between 1 and 150 lbs."))
      end
    end

    def state(s)
      valid_state?(s) ? s : (raise ShippingCalcError.new("Invalid state for recipient"))
    end

    def valid_state?(s)
      US_STATES.include?(s)
    end

    def zip_code(code)
      if code.class != Fixnum
        raise ShippingCalcError.new("Zip Code must be a number. Perhaps you're using a string?")
      end
      code.to_s =~ /\d{5}/ ? code.to_s : (raise ShippingCalcError.new("Invalid zip code for recipient"))
    end

  end
end
