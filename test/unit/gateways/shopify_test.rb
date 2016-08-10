require 'test_helper'

class ShopifyTest < Test::Unit::TestCase
  def setup
    @gateway = ShopifyGateway.new(api_key: 'api_key',
                                  password: 'password',
                                  shop_name: 'shop_name')
  end

  def test_void_calls_refund
    transaction_id = 123
    transaction = stub(amount: 1, id: transaction_id)
    refunder_instance = stub(perform: true)
    ::ShopifyAPI::Transaction.expects(:find).returns(transaction)
    ShopifyRefunder.expects(:new).returns(refunder_instance)

    refunder_instance.expects(:perform).once
    @gateway.void(123, { order_id: '123' })
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
    transaction = stub(amount: 1)
    ::ShopifyAPI::Transaction.stubs(:find).returns(transaction)
    assert_raises(::ActiveMerchant::Billing::ShopifyGateway::CreditedAmountBiggerThanTransaction) { @gateway.refund(10000, 123, { order_id: '123', reason: 'reason' }) }
  end

  def test_response_value_of_unsuccessful_refund
    transaction_id = 123
    transaction = stub(amount: 1, id: transaction_id)
    refund = stub(errors: [])
    ::ShopifyAPI::Transaction.stubs(:find).returns(transaction)
    ::ShopifyAPI::Refund.stubs(:create).returns(refund)
    assert_success(@gateway.refund(100, transaction_id, { order_id: '123', reason: 'reason' }))
  end

  def test_reponse_value_of_successful_refund
    transaction_id = 123
    transaction = stub(amount: 1, id: transaction_id)
    errors = stub(messages: { error: 'error1' })
    refund = stub(errors: errors)
    ::ShopifyAPI::Transaction.stubs(:find).returns(transaction)
    ::ShopifyAPI::Refund.stubs(:create).returns(refund)
    assert_failure(@gateway.refund(100, transaction_id, { order_id: '123', reason: 'reason' }))
  end
end
