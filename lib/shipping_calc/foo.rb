    def shipment_item(dimensions)
      raise StandardError.new("Invalid shipment dimensions") unless (dimensions =~ /\d+x\d+x\d+/)

      d = dimensions.split("x")
    end

shipment_item("23x3")
