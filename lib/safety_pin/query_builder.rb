require 'rest-client'
require 'json'

module SafetyPin
  class QueryBuilder
    def self.execute(query)
      response = RestClient.get url, {params: query}
      results = JSON.parse(response)
      paths = results.fetch("hits").map {|hit| hit.fetch("path") }
      paths.map {|path| Node.find(path) }
    rescue RestClient::ExceptionWithResponse => e
      query_string = query.map {|k,v| "#{k}=#{v}"}.join("&")
      raise QueryBuilderError.new("returned error status #{e.http_code} for query #{query_string.inspect}")
    end

    def self.url
      url = URI.parse(JCR.options.fetch(:hostname))
      url.path = "/bin/querybuilder.json"
      url.user = JCR.options.fetch(:username)
      url.password = JCR.options.fetch(:password)
      url.to_s
    end
  end

  class QueryBuilderError < Exception; end
end