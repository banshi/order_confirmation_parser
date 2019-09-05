describe 'OrderConfirmationParser::Parser' do
  describe 'valid pdf' do
    before(:all) do
      @input = './spec/sample_files/valid.pdf'
      @service = OrderConfirmationParser::Parser.new(@input)
      @service.exec
    end

    it 'has correct values set on order' do
      order = @service.order
      line_items = @service.order.line_items

      expect(order.confirmed_on).to eq(DateTime.new(2014, 8, 10, 12, 39))
      expect(order.vendor_name).to eq('MAINTENANCE U.S.A.')
      expect(order.order_number).to eq('12345678')
      expect(order.status).to eq('pending')
      expect(order.po_number).to eq('22551-1')
      expect(order.total).to eq(713.79)
      expect(line_items.length).to eq(2)
      expect(line_items[0].item_number).to eq('105350')
      expect(line_items[1].item_number).to eq('105342')
    end
  end

  describe 'invalid pdf' do
    before(:all) do
      @input = './spec/sample_files/invalid.pdf'
      @service = OrderConfirmationParser::Parser.new(@input)
    end

    it 'raises error' do
      expect{ @service.exec }.to raise_error(RuntimeError)
    end

    it 'has errors on the order' do
      @service.exec rescue nil
      expect(@service.order.valid?).to be_falsy
      expect(@service.order.errors.full_messages.length).to eq(3)
    end
  end
end
