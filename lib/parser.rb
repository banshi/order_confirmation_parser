require 'pdf-reader'
require 'date'

module OrderConfirmationParser
  class Parser
    CONFIRMED_ON = /\d{1,2}\/\d{1,2}\/\d{1,2} \d{1,2}:\d{1,2}/
    VENDOR_NAME = /PAGE 1\n\n(.*)\n\nCUSTOMER NAME/m
    ORDER_NUMBER = /ORDER NUMBER : (\d+)/
    STATUS = /STATUS : (\S+)/
    PO_NUMBER = /PURCHASE ORDER NUMBER : (\S+)/
    TOTAL = /NET\s+(\d+[.]?(\d+)?)/
    LINE_ITEMS = /---\n(.*)\n\s+---/m
    LINE_ITEM = /\s*(?<line_number>\d+)\s+/

    PROCESSIBLE_FIELDS = %w(confirmed_on vendor_name order_number status po_number total)

    def initialize(input_file = ARGV[0])
      @content = parse_content(input_file)
    end

    def exec
      parse_fields

      if order.save
        line_items = parse_line_items
        save_line_items(line_items)
      else
        errors = order.errors.full_messages.join(', ')
        raise RuntimeError.new("Order couldn't be saved because of errors: #{errors}")
      end

      puts order.as_json
    end

    def order
      @order ||= Order.new
    end

    private

    def parse_fields
      fields.each do |field|
        value = send("parse_#{field}")
        send("set_#{field}", value)
      end
    end

    def fields
      PROCESSIBLE_FIELDS
    end

    def parse_confirmed_on
      (m = @content.match(CONFIRMED_ON)) && m[0]
    end

    def parse_vendor_name
      (m = @content.match(VENDOR_NAME)) && m[1]
    end

    def parse_order_number
      (m = @content.match(ORDER_NUMBER)) && m[1]
    end

    def parse_status
      (m = @content.match(STATUS)) && m[1]
    end

    def parse_po_number
      (m = @content.match(PO_NUMBER)) && m[1]
    end

    def parse_total
      (m = @content.match(TOTAL)) && m[1]
    end

    def parse_line_items
      line_items = (m = @content.match(LINE_ITEMS)) && m[1]
      line_items.try(:split, "\n\n") || []
    end

    def save_line_items(line_items)
      line_items.each do |line_item|
        %r{
          \s*(?<line_number>\d+)
          \s+(?<item_number>\d+)
          \s+(?<description>(.)+?)
          \s{3,}(?<quantity>\d+)
          \s+(?<unit_price>\d+[.]?(\d+)?)
        }x =~ line_item
        order_line_item = order.line_items.build
        order_line_item.line_number = line_number
        order_line_item.item_number = item_number
        order_line_item.description = description
        order_line_item.quantity = quantity
        order_line_item.unit_price = unit_price
        order_line_item.save
      end
    end

    def set_order_number(value)
      order.order_number = value
    end

    def set_total(value)
      order.total = value
    end

    def set_po_number(value)
      order.po_number = value
    end

    def set_confirmed_on(value)
      order.confirmed_on = DateTime.strptime(value, '%d/%m/%y %H:%M') rescue nil
    end

    def set_vendor_name(value)
      order.vendor_name = value
    end

    def set_status(value)
      order.status = Order.statuses[value.downcase] if value
    end

    def parse_content(input_file)
      reader = PDF::Reader.new(input_file)
      reader.pages.first.text
    end
  end
end
