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
end
