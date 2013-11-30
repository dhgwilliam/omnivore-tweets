#!/usr/bin/env ruby
require 'nokogiri'
require 'httparty'
require 'tactful_tokenizer'
require 'bitly'
require 'dotenv'
require 'yaml_record'

Dotenv.load
TOKENIZER = TactfulTokenizer::Model.new

Bitly.configure do |config|
  config.api_version = 3
  config.login = ENV['API_LOGIN']
  config.api_key = ENV['API_KEY']
end
BITLY = Bitly.client

class Blog
  @@url = 'http://www.bookforum.com/blog'
  class << self
    def url
      @@url
    end

    def doc
      @doc || Nokogiri::HTML(HTTParty.get(@@url))
    end

    def post_urls
      headlines = doc.css('h1 a')
      headlines = headlines.select {|node| node.attributes["name"] && node.attributes["name"].value.match(/entry/)}
      headlines.map! {|node| node.attributes["href"].value}
      headlines.map {|url| 
        url.slice!(/\/blog/)
        @@url + url }
    end

    def posts
      Post.all
    end

    def fetch_posts
      post_urls.each do |url|
        if Post.find_by_attribute(:url, url)
          puts "found #{url}"
          Post.find_by_attribute(:url, url)
        else
          puts "fetching #{url}"
          PostController.new(:url => url)
        end
      end 
      Post.all
    end
  end
end

class Post < YamlRecord::Base
  attr_reader :url
  properties :url, :sentences, :links, :title
  source File.join('data', 'posts')
end

class PostController
  def initialize(args)
    @url       = args[:url]
    @raw       = args[:raw] || raw
    @doc       = doc
    @to_html   = to_html
    @sentences = sentences
    @links     = links
    @title     = title
    Post.find_by_attribute(:url, @url) || Post.create(:url => @url,
                :sentences => @sentences,
                :links => @links,
                :title => @title)
  end

  def raw
    @raw || Nokogiri::HTML(HTTParty.get(@url))
  end

  def doc
    @doc || raw.css('div.Entry div.Padding p').first
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

  def title
    @title || raw.css('div.Entry div.Padding div.Topper h1').first.children.children.first.content
  end
end

class Sentence
  attr_reader :doc

  def initialize(args)
    @doc       = args[:doc]
    @content   = content
    @url       = url
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
    if @url
      @short_url ||= BITLY.shorten(@url).short_url 
    else
      nil
    end
  end

  def display
    display_content = content
    display_content.chop! if display_content.end_with?('.')
    "#{display_content}: #{short_url}" if @url
  end
end
