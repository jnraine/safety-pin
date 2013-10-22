require 'rest-client'
require 'json'

module SafetyPin
  class QueryBuilder
    def self.execute(query)
      response = RestClient.get url, {params: query}
      results = JSON.parse(response)
      paths = results.fetch("hits").map {|hit| hit["path"] }
      paths.map {|path| Node.find(path) }
    end

    def self.url
      url = URI.parse(JCR.options.fetch(:hostname))
      url.path = "/bin/querybuilder.json"
      url.user = JCR.options.fetch(:username)
      url.password = JCR.options.fetch(:password)
      url.to_s
    end
  end
end