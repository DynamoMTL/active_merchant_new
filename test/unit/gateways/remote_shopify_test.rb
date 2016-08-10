require 'test_helper'

class RemoteStripeTest < Test::Unit::TestCase
  def setup
    @gateway = ShopifyGateway.new(fixtures(:shopify))

    @refund_amount = 50
    @refund_amount_in_cents = @refund_amount * 100
    @order = create_fulfilled_paid_shopify_order
    @transaction = ::ShopifyAPI::Order.find(@order.id).transactions.first

    @refund_options = { order_id: @order.id, reason: 'Object is malfunctioning' }
    @void_options = { order_id: @order.id, reason: 'Payment voided' }
  end

  def teardown
    @order.destroy
  end

  def test_successful_void
    assert response = @gateway.void(@transaction.id, @void_options)
    assert_success response
  end

  def test_successful_full_refund
    assert response = @gateway.refund(@refund_amount_in_cents, @transaction.id, @refund_options)
    assert_success response
  end

  def test_successful_partial_refund
    assert response = @gateway.refund(@refund_amount_in_cents / 2, @transaction.id, @refund_options)
    assert_success response
  end

  private

  def create_fulfilled_paid_shopify_order
    order = ::ShopifyAPI::Order.new
    order.email = 'cab@godynamo.com'
    order.test = true
    order.fulfillment_status = 'fulfilled'
    order.line_items = [
      {
        variant_id: '447654529',
        quantity: 1,
        name: 'test',
        price: @refund_amount,
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
        kind: 'capture',
        status: 'success',
        amount: @refund_amount
      }
    ]
    order.financial_status = 'paid'
    order.save

    order
  end
end
