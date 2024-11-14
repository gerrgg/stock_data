# require 'nokogiri'
# require 'selenium-webdriver'
# require 'open-uri'

# require 'nokogiri'
# require 'selenium-webdriver'
# require 'open-uri'
# require 'fileutils'

# class PriceLogger
#   def initialize(symbols, verbose)
#     @symbols = symbols.map(&:upcase)
#     @verbose = verbose
#     @stocks_dir = "stocks"
#     @options = Selenium::WebDriver::Chrome::Options.new
#     @options.add_argument('--headless')
    
#     puts "Initializing headless browser" if @verbose
#     @driver = Selenium::WebDriver.for :chrome, options: @options

#     # Open each stock's page in a separate tab and store the window handle
#     @tabs = {}
#     @symbols.each do |symbol|
#       puts "Opening new tab for #{symbol}" if @verbose
#       @driver.execute_script("window.open()")  # Open a new tab
#       @driver.switch_to.window(@driver.window_handles.last)
#       puts "Navigating to Yahoo Finance page for #{symbol}" if @verbose
#       @driver.get("https://finance.yahoo.com/quote/#{symbol}")
#       @tabs[symbol] = @driver.window_handle
#       puts "#{symbol} tab opened and page loaded" if @verbose
#     end
#     @driver.switch_to.window(@driver.window_handles.first)  # Return to the first tab
#     puts "Browser setup complete\n" if @verbose
#   end

#   def get_price(symbol)
#     tab = @tabs[symbol]
#     unless tab
#       puts "No tab found for #{symbol}" if @verbose
#       return nil
#     end

#     # Switch to the tab for the symbol
#     puts "Switching to tab for #{symbol}" if @verbose
#     @driver.switch_to.window(tab)
#     puts "Refreshing page for #{symbol} to get latest price" if @verbose
#     @driver.navigate.refresh  # Refresh to ensure updated data
    
#     begin
#       element = @driver.find_element(css: '.livePrice span')
#       price = element.text if element
#       puts "Fetched price for #{symbol}: #{price}" if @verbose && price
#       price
#     rescue Selenium::WebDriver::Error::NoSuchElementError
#       puts "Price element not found for #{symbol}" if @verbose
#       nil
#     end
#   end

#   def maybe_create_folder(symbol)
#     file_path = "#{@stocks_dir}/#{symbol}.txt"
#     unless File.exist?(file_path)
#       puts "Creating directory for #{symbol}" if @verbose
#       FileUtils.mkdir_p(File.dirname(file_path))
#     end
#   end

#   def log_price(symbol)
#     price = get_price(symbol)
#     file_path = "#{@stocks_dir}/#{symbol}.txt"
    
#     maybe_create_folder(symbol)  # Ensure the folder exists
    
#     if File.exist?(file_path)
#       File.open(file_path, 'a') do |file|  # Append mode
#         str = "#{Time.now()}: $#{price}\n"
#         file.write(str)
#         puts str if @verbose
#       end
#     else
#       File.write(file_path, "#{symbol} stock data\n#{price}\n")
#     end
#   end
# end

require 'nokogiri'
require 'selenium-webdriver'
require 'open-uri'
require 'fileutils'
require 'concurrent-ruby'

class PriceLogger
  def initialize(symbols, verbose)
    @symbols = symbols.map(&:upcase)
    @verbose = verbose
    @stocks_dir = "stocks"
    @options = Selenium::WebDriver::Chrome::Options.new
    @options.add_argument('--headless')

    if @verbose
      puts "Launching browser for each worker in headless mode..."
    end

    # Create a thread-safe hash to store driver instances for each symbol
    @drivers = Concurrent::Hash.new
    @symbols.each do |symbol|
      driver = Selenium::WebDriver.for :chrome, options: @options
      driver.get("https://finance.yahoo.com/quote/#{symbol}")
      @drivers[symbol] = driver
      puts "Initialized driver and navigated to page for #{symbol}." if @verbose
    end
  end

  def get_price(symbol)
    driver = @drivers[symbol]
    return nil unless driver

    puts "Fetching price for #{symbol}..." if @verbose
    driver.navigate.refresh
    puts "Page refreshed for updated data on #{symbol}." if @verbose
    
    element = driver.find_element(css: '.livePrice span')
    price = element.text if element
    puts "Retrieved price for #{symbol}: #{price}" if @verbose
    price
  end

  def maybe_create_folder(symbol)
    file_path = "#{@stocks_dir}/#{symbol}.txt"
    unless File.exist?(file_path)
      puts "Creating directory for stock data files..." if @verbose
      FileUtils.mkdir_p(File.dirname(file_path))
      puts "Directory created at #{File.dirname(file_path)}." if @verbose
    end
  end

  def log_price(symbol)
    puts "Logging price for #{symbol}..." if @verbose
    price = get_price(symbol)
    file_path = "#{@stocks_dir}/#{symbol}.txt"
    
    maybe_create_folder(symbol)

    if File.exist?(file_path)
      File.open(file_path, 'a') do |file|  # Append mode
        str = "#{Time.now}: $#{price}\n"
        file.write(str)
        puts str if @verbose
      end
    else
      File.write(file_path, "#{symbol} stock data\n#{price}\n")
    end
  end

  def monitor_prices
    # Use a thread pool to log prices concurrently for each stock
    pool = Concurrent::FixedThreadPool.new(@symbols.size)

    @symbols.each do |symbol|
      pool.post do
        loop do
          log_price(symbol)
          sleep 60  # Wait 60 seconds before updating again
        end
      end
    end

    pool.shutdown
    pool.wait_for_termination
  end

  def close_drivers
    @drivers.each_value(&:quit)
    puts "All drivers closed." if @verbose
  end
end

# Usage
symbols = ['QQQ', 'SPY']
logger = PriceLogger.new(symbols, true)
trap("SIGINT") { logger.close_drivers; exit }

logger.monitor_prices
