require 'spec_helper.rb'

describe JCR::Query do
  before do
    JCR.login(:hostname => "http://localhost:4502", :username => "admin", :password => "admin")
  end

  after do
    JCR.logout
  end

  describe ".execute" do
    before do
      @node = JCR::Node.create("/content/foo")
      @node["bar"] = "baz"
      @node.save
    end
    
    after { @node.destroy }
    
    it "can lookup nodes given a valid JCR-SQL2 query string" do
      nodes = JCR::Query.execute("SELECT * FROM [nt:base] WHERE [nt:base].bar IS NOT NULL")
      nodes.first["bar"].should_not be_nil
    end
  end
  
  # it "can query for nodes of a specific type" do
  #   pending
  #   nodes = JCR::Query.type("cq:Page")
  # end
  # 
  # it "can query for nodes beneath a specific path" do
  #   pending
  #   nodes = JCR::Query.path("/content/sfu")
  # end
  # 
  # it "can query for nodes with a specific property" do
  #   pending
  #   nodes = JCR::Query.where("cq:Template" => "/apps/sfu/templates/basicpage")
  # end
  # 
  # it "can chain together query methods to build a query" do
  #   pending
  #   nodes = JCR::Query.path("/content").type("nt:unstructured").where("jcr:title" => "Open House")
  # end
end