# getting started

So far I've been working on this in `pry`, so to get started:

  * `git clone https://github.com/dhgwilliam/omnivore-tweets.git`
  * `cd omnivore-tweets`
  * `bundle install`
  * add your bit.ly login and api key to `.env`:

        API_LOGIN='dhgwilliam'
        API_KEY='R_abcdef0123456789'

  * `pry -r './omnivore.rb' -e 'blog = Blog.new'`
  * at this point, you should be able to navigate around the `blog` object. Try
`blog.posts.first.sentences.each {|s| puts s.display}`
