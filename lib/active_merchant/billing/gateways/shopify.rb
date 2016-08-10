require 'shopify_api'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class ShopifyGateway < Gateway
      class TransactionNotFoundError < Error; end
      class CreditedAmountBiggerThanTransaction < Error; end

      self.homepage_url = 'https://shopify.ca/'
      self.display_name = 'Shopify'

      def initialize(options = {})
        requires!(options, :api_key)
        requires!(options, :password)
        requires!(options, :shop_name)

        @api_key = options[:api_key]
        @password = options[:password]
        @shop_name = options[:shop_name]

        init_shopify_api!

        super
      end

      def void(transaction_id, options = {})
        order_id = options[:order_id]
        voider = ShopifyVoider.new(transaction_id, order_id)
        voider.perform
      end

      def refund(money, transaction_id, options = {})
        refunder = ShopifyRefunder.new(money, transaction_id, options)
        refunder.perform
      end

      private

      attr_reader :api_key, :password, :shop_name

      def init_shopify_api!
        ::ShopifyAPI::Base.site = shop_url
      end

      def shop_url
        "https://#{api_key}:#{password}@#{shop_name}"
      end
    end
  end
end

class ShopifyVoider
  def initialize(transaction_id, order_id)
    @transaction = ::ShopifyAPI::Transaction.find(transaction_id, params: { order_id: order_id })
  end

  def perform
    raise ActiveMerchant::Billing::ShopifyGateway::TransactionNotFoundError if transaction.nil?

    transaction.kind = 'void'
    transaction.save
  end

  private

  attr_reader :transaction
end

class ShopifyRefunder
  def initialize(credited_money, transaction_id, options)
    @refund_reason = options[:reason]
    @order_id = options[:order_id]
    @credited_money = BigDecimal.new(credited_money)
    @transaction = ::ShopifyAPI::Transaction.find(transaction_id, params: { order_id: order_id })
  end

  def perform
    raise ActiveMerchant::Billing::ShopifyGateway::TransactionNotFoundError if transaction.nil?

    # NOTE(cab): This should be refactored when we are sure that this is the
    # behavior we want
    if full_refund?
      perform_refund_on_shopify
    elsif partial_refund?
      perform_refund_on_shopify
    else
      raise ActiveMerchant::Billing::ShopifyGateway::CreditedAmountBiggerThanTransaction
    end
  end

  private

  def perform_refund_on_shopify
    ::ShopifyAPI::Refund.create(order_id: order_id,
                                shipping: { amount: 0 },
                                note: refund_reason,
                                notify: false,
                                restock: false,
                                transactions: [{
                                  parent_id: transaction.id,
                                  amount: amount_to_dollars(credited_money),
                                  gateway: 'shopify-payments',
                                  kind: 'refund'
                                }])
  end

  def full_refund?
    credited_money == amount_to_cents(transaction.amount)
  end

  def partial_refund?
    credited_money < amount_to_cents(transaction.amount)
  end

  def amount_to_cents(amount)
    BigDecimal.new(amount)
  end

  def amount_to_dollars(amount)
    BigDecimal.new(amount) / 100
  end

  attr_accessor :credited_money, :refund_reason, :transaction, :order_id
end
