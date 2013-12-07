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

      # i tried to refactor url.split('/').last to Post#url but it didn't work 
      # at all and I have no idea why. See remnants in the lib.
      posts = Blog.posts.sort_by! { |p|  p.url.split('/').last }
      posts.each {|p| puts "#{p.url.split('/').last} - #{p.title}" }
    end
  end

  command 'links' do
    on :post=, 'Post URL/ID'

    run do |o|
      p = Post.find_by_attribute(:url, "#{Blog.url}/#{o.to_hash[:post]}")
      p.sentences.each {|s| puts s.display if s.display }
    end
  end
end

opts.parse
