# getting started

  * `git clone https://github.com/dhgwilliam/omnivore-tweets.git`
  * `cd omnivore-tweets`
  * `bundle install`
  * add your bit.ly login and api key to `.env`:

        API_LOGIN='dhgwilliam'
        API_KEY='R_abcdef0123456789'

  * `touch data/posts.yml`
  * `bin/omnivore -h`
  * `bin/omnivore update`
