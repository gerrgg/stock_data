class PriceLogger
  def initialize(symbol, verbose)
    @symbol = symbol.upcase
    @url = "https://finance.yahoo.com/quote/#{symbol}/"
    @stocks_dir = "stocks"
    @file_path = "#{@stocks_dir}/#{@symbol}.txt"
    @verbose = verbose
  end

  def get_price
    url = 'https://finance.yahoo.com/quote/QQQ/'
    html_content = URI.open(url).read
    parsed_content = Nokogiri::HTML(html_content)
    element = parsed_content.at_css('.livePrice')
    return element.text if element
  end

  def log_price
    price = get_price()
    if File.exist?(@file_path)
      File.open(@file_path, 'a') do |file|  # Append mode
        str = "#{Time.now()}: $#{price}\n"
        file.write(str)
        puts str if @verbose
      end
    else
      File.write(@file_path, "#{@symbol} stock data\n#{price}\n")
    end
  end

  def log_price_on_loop(interval)
    
  end
end