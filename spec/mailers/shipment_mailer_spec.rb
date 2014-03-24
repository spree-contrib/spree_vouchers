require 'spec_helper'
require 'email_spec'

describe Spree::ShipmentMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  let(:shipment) do
    order = stub_model(Spree::Order)
    product = stub_model(Spree::Product, :name => %Q{The "BEST" product})
    variant = stub_model(Spree::Variant, :product => product)
    line_item = stub_model(Spree::LineItem, :variant => variant, :order => order, :quantity => 1, :price => 5)

    vouchers = [FactoryGirl.create(:voucher)]
    line_item.stub(:vouchers => vouchers)
    shipment = stub_model(Spree::Shipment)
    shipment.stub(:line_items => [line_item], :order => order)
    shipment.stub(:tracking_url => "TRACK_ME")

    SpecManifestItem = Struct.new(:line_item, :variant, :quantity, :states)

    shipment.stub(:manifest => [SpecManifestItem.new(line_item, variant, 1, nil)])

    shipment
  end

  context "Shipment contains vouchers" do
    it "displays the vouchers" do
      message = Spree::ShipmentMailer.shipped_email(shipment)
      message.body.should include(Spree.t(:voucher_number))
    end
  end
end
