require './price_logger.rb'

stocks = ['QQQ', 'SPY']

logger = PriceLogger.new(stocks, true)

loop do
  stocks.each {|stock| logger.log_price(stock)}
end


