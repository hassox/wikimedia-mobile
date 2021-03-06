# Server is a model class that represents a media wiki server.
# This is the base model for getting articles and eventually login-logout stuff.
class Server
  attr :host
  attr :port
  
  # Whenever you create a new article
  # you need to give it a host and a port
  def initialize(host, port)
    @host, @port = host, port
  end
  
  # What is the base URL for this server?
  def base_url
    "http://#{@host}:#{@port}"
  end
  
  def article(title)
    uri = URI::escape title
    Article.new(self, title, "/wiki/Special:Search?search=#{uri}")
  end
  
  def file(title)
    Article.new(self, title, "/wiki/File:#{title}")
  end

  # Grab a random article from this server
  def random_article
    article = Article.new(self)
    article.html = fetch("/wiki/Special:Random")
    Parsers::XHTML.parse(article)
    return article
  end
  
  # In the future, this method might use a cache...
  # 
  # paths must start with a /
  def fetch(path)
    begin
      Merb.logger.debug("loading... " + base_url + path)
      result = (Curl::Easy.perform(base_url + path) do |curl|
        # This configures Curl::Easy to follow redirects
        curl.follow_location = true
      end).body_str
      Merb.logger.debug("loaded #{result.size} characters")
      result
    rescue Curl::Err::HostResolutionError, Curl::Err::GotNothingError
      Merb.logger.error("Could not connect to " + base_url + path)
      return ""
    end
  end
end