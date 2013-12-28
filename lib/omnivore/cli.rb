#!/usr/bin/env ruby
$:.unshift('./lib')
require 'omnivore'
require 'slop'

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
    on :tweets, 'Tweet length links only (implies --shorten)'
    on :all, 'Print all tweet length links (HUGE)'
    on :shorten, 'Use bit.ly link shortener'

    run do |o|
      # TODO i should probably implement a class for this task
      posts = if o.to_hash[:all]
                Post.all
              else
                [ Post.find_by_attribute(:url, "#{Blog.url}/#{o.to_hash[:post]}") ]
              end

      display_args =  if o.to_hash[:shorten] or o.to_hash[:tweets]
                        { :shorten => true }
                      else
                        { :shorten => false }
                      end

      sentences = posts.collect{|p|p.sentences}.flatten.select{|s|s.url}
      sentences.select! {|s| s.display(display_args).length <= 140 } if o.to_hash[:tweets]
      sentences.each {|s| puts "#{s.display(display_args)} (#{s.display(display_args).length})" }
    end
  end
end

opts.parse
