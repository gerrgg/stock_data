require 'open-uri'
require 'nokogiri'
require './price_logger.rb'
# url = 'https://www.tradingview.com/symbols/NASDAQ-QQQ/'

logger = PriceLogger.new('QQQ', true)

loop do
  logger.log_price
  sleep 10
end


