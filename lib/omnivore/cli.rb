#!/usr/bin/env ruby
$:.unshift('./lib')
require 'omnivore'
require 'slop'
require 'pry'

opts = Slop.new do
  on '-h', :help, 'Display this documentation' do
    puts "Commands implemented so far:"
    puts "update  -  fetch and save any new posts"
    puts "posts   -  display saved post titles"
    puts "links   -  display links from --post [ID]"
  end

  command 'update' do
    run do
      Blog.fetch_posts
    end
  end

  command 'posts' do
    run do
      posts = Blog.posts.sort_by! { |p|  p.uid }
      posts.each {|p| puts "#{p.uid} - #{p.title}" }
    end
  end

  command 'links' do
    on :post=, 'Post URL/ID'
    on :tweets, 'Tweet length links only'
    on :all, 'Print all tweet length links (HUGE)'

    run do |o|
      # i should probably implement a class for this task
      posts = if o.to_hash[:all]
        Post.all
      else
        [ Post.find_by_attribute(:url, "#{Blog.url}/#{o.to_hash[:post]}") ]
      end

      sentences = posts.collect{|p|p.sentences}.flatten.select{|s|s.display}
      sentences.select! {|s| s.display.length <= 140 } if o.to_hash[:tweets]
      sentences.each {|s| puts "#{s.display} (#{s.display.length})" }
    end
  end
end

opts.parse
