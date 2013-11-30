require 'nokogiri'
require 'httparty'
require 'tactful_tokenizer'
require 'bitly'
require 'dotenv'

Dotenv.load
TOKENIZER = TactfulTokenizer::Model.new

Bitly.configure do |config|
  config.api_version = 3
  config.login = ENV['API_LOGIN']
  config.api_key = ENV['API_KEY']
end
BITLY = Bitly.client

class Blog
  attr_reader :url

  def initialize(args = {})
    @url       = args[:url] || 'http://www.bookforum.com/blog'
    @doc       = doc
    @post_urls = post_urls
    @posts     = posts
  end

  def doc
    @doc || Nokogiri::HTML(HTTParty.get(@url))
  end

  def post_urls
    headlines = @doc.css('h1 a')
    headlines = headlines.select {|node| node.attributes["name"] && node.attributes["name"].value.match(/entry/)}
    headlines.map! {|node| node.attributes["href"].value}
    headlines.map {|url| 
      url.slice!(/\/blog/)
      @url + url }
  end

  def posts
    @posts || fetch_posts
  end

  def fetch_posts
    @posts = []
    post_urls.each do |url|
      puts "fetching #{url}"
      @posts << Post.new(:url => url)
    end 
    @posts
  end

  # private :fetch_posts
end

class Post
  attr_reader :url


  def initialize(args)
    @url       = args[:url]
    @doc       = doc
    @to_html   = to_html
    @sentences = sentences
    @links     = links
  end

  def doc
    @doc || Nokogiri::HTML(HTTParty.get(@url)).css('div.Entry div.Padding p').first
  end

  def to_html
    @to_html || doc.to_html
  end

  def sentences
    if @sentences
      @sentences
    else
      @sentences = []
      TOKENIZER.tokenize_text(to_html).each {|token| @sentences << Sentence.new(:doc => token)}
      @sentences
    end
  end

  def links
    links = @sentences.select {|s| true if s.respond_to?(:url) }
    links.map { |sentence| sentence.url }
  end

end

class Sentence
  attr_reader :doc

  def initialize(args)
    @doc       = args[:doc]
    @content   = content
    @url       = url
    @short_url = short_url if @url
  end

  def content
    begin
      Nokogiri::HTML(@doc).content
    rescue
      nil
    end
  end

  def url
    if @url 
      @url
    else
      begin
        Nokogiri::HTML(@doc).css('a').first.attribute("href").value
      rescue
        nil
      end
    end
  end

  def has_link?
    has_link = false
    has_link = true if url
  end

  def short_url
    @short_url || BITLY.shorten(@url).short_url
  end

  def display
    "#{content}: #{short_url}"
  end
end
