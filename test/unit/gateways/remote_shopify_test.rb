require 'test_helper'

class RemoteStripeTest < Test::Unit::TestCase
  def setup
    @gateway = ShopifyGateway.new(fixtures(:shopify))

    @order = create_shopify_order
    @transaction = ::ShopifyAPI::Order.find(@order.id).transactions.first
    @amount = BigDecimal.new(@transaction.amount) * 100

    @options = { order_id: @order.id, reason: 'Object is malfunctioning' }
  end

  def teardown
    @order.destroy
  end

  def test_successful_full_refund
    assert response = @gateway.refund(@amount, @transaction.id, @options)
    assert_success response
  end

  private

  def create_shopify_order
    order = ::ShopifyAPI::Order.new
    order.email = 'cab@godynamo.com'
    order.fulfillment_status = 'partial'
    order.line_items = [
      {
        variant_id: '447654529',
        quantity: 1,
        name: 'test',
        price: 140,
        title: 'title'
      }
    ]
    order.customer = { first_name: 'Paul',
                       last_name: 'Norman',
                       email: 'paul.norman@example.com' }

    order.billing_address = {
      first_name: 'John',
      last_name: 'Smith',
      address1: '123 Fake Street',
      phone: '555-555-5555',
      city: 'Fakecity',
      province: 'Ontario',
      country: 'Canada',
      zip: 'K2P 1L4'
    }
    order.shipping_address = {
      first_name: 'John',
      last_name: 'Smith',
      address1: '123 Fake Street',
      phone: '555-555-5555',
      city: 'Fakecity',
      province: 'Ontario',
      country: 'Canada',
      zip: 'K2P 1L4'
    }
    order.transactions = [
      {
        kind: 'authorization',
        status: 'success',
        amount: 50.0
      }
    ]
    order.financial_status = 'partially_paid'
    order.save

    order
  end
end

