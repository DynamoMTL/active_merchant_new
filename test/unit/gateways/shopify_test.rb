require 'test_helper'

class ShopifyTest < Test::Unit::TestCase
  def setup
    @gateway = ShopifyGateway.new(api_key: 'api_key',
                                  password: 'password',
                                  shop_name: 'shop_name')
  end

  def test_void_with_not_found_transaction
    ::ShopifyAPI::Transaction.expects(:find).returns(nil)
    assert_raises(::ActiveMerchant::Billing::ShopifyGateway::TransactionNotFoundError) { @gateway.void(123, order_id: '123') }
  end

  def test_refund_with_not_found_transaction
    ::ShopifyAPI::Transaction.expects(:find).returns(nil)
    assert_raises(::ActiveMerchant::Billing::ShopifyGateway::TransactionNotFoundError) { @gateway.refund(123, 123, { order_id: '123', reason: 'reason' }) }
  end

  def test_refund_with_credit_to_big
    transaction = stub(amount: 100)
    ::ShopifyAPI::Transaction.stubs(:find).returns(transaction)
    assert_raises(::ActiveMerchant::Billing::ShopifyGateway::CreditedAmountBiggerThanTransaction) { @gateway.refund(1000, 123, { order_id: '123', reason: 'reason' }) }
  end

  def test_full_refund
    transaction_id = 123
    transaction = stub(amount: 100, id: transaction_id)
    refund = stub(success?: true)
    ::ShopifyAPI::Transaction.stubs(:find).returns(transaction)
    ::ShopifyAPI::Refund.stubs(:create).returns(refund)
    assert_success(@gateway.refund(100, transaction_id, { order_id: '123', reason: 'reason' }))
  end
end
