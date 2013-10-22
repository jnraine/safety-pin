module SafetyPin
  class JCR
    include_class('java.lang.String') {|package,name| "J#{name}" }
    include_class 'javax.jcr.SimpleCredentials'
    include_class 'org.apache.jackrabbit.commons.JcrUtils'

    def self.login(opts = {})
      @options = opts
      repository = JcrUtils.get_repository(parse_hostname(opts[:hostname]))
      creds = SimpleCredentials.new(opts[:username], JString.new(opts[:password]).to_char_array)
      @@session = repository.login(creds)
    end

    def self.options
      @options
    end

    def self.logout
      session.logout
      not session.live?
    end

    def self.logged_in?
      session.live?
    end

    def self.logged_out?
      not logged_in?
    end

    def self.session
      @@session
    end

    def self.parse_hostname(hostname)
      url = URI.parse(hostname)
      url.path = "/crx/server" if url.path == ""
      url.to_s
    end

    def self.dev_login
      login(:hostname => "http://localhost:4502", :username => ENV["JCR_USERNAME"], :password => ENV["JCR_PASSWORD"])
    end
  end
end