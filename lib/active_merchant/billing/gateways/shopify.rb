module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class ShopifyGateway < Gateway
      class TransactionNotFoundError < Error; end

      self.homepage_url = 'https://shopify.ca/'
      self.display_name = 'Shopify'

      def initialize(options = {})
        requires!(options, :login)
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
        refund = options[:originator]
        refunder = ShopifyRefunder.new(money, transaction_id, refund)
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
    raise TransactionNotFoundError if transaction.nil?

    transaction.kind = 'void'
    transaction.save
  end

  private

  attr_reader :transaction
end

class ShopifyRefunder
  def initialize(credited_money, transaction_id, refund)
    @refund = refund
    @credited_money = BigDecimal.new(credited_money)
    @transaction = ::ShopifyAPI::Transaction.find(transaction_id, params: { order_id: pos_order_id })
  end

  def perform
    if full_refund?
      perform_full_refund_on_shopify
    elsif partial_refund?
      raise NotImplementedError
    else
      raise NotImplementedError
    end
  end

  private

  def perform_full_refund_on_shopify
    ::ShopifyAPI::Refund.create({ shipping: { full_refund: true },
                                  note: refund.reason.name,
                                  notify: false,
                                  restock: false,
                                  transaction: suggested_transaction },
                                params: { order_id: pos_order_id })
  end

  def suggested_transaction
    ::ShopifyAPI::Refund.calculate({ shipping: { full_refund: true } },
                                   params: { order_id: pos_order_id })
  end

  def pos_order_id
    refund.pos_order_id
  end

  def full_refund?
    credited_money == amount_to_cents(transaction.amount)
  end

  def partial_refund?
    BigDecimal.new(credit_money) < amount_to_cents(transaction.amount)
  end

  def amount_to_cents(amount)
    amount * 100
  end

  attr_accessor :credited_money, :refund, :transaction
end
