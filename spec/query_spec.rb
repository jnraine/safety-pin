require 'spec_helper.rb'

describe JCR::Query do
  before do
    JCR.login(:hostname => "http://localhost:4502", :username => "admin", :password => "admin")
  end

  after do
    JCR.logout
  end

  context ".execute" do
    # it "can execute a query" do
    #   nodes = JCR::Query.execute("SELECT * FROM [cq:Page]")
    #   nodes.first.should be_a JCR::Node
    # end
    
    context "when a property is present" do
      it "can lookup nodes based on the existence of a property property value" do
        nodes = JCR::Query.execute("SELECT * FROM [nt:base] WHERE [nt:base].prop1 IS NOT NULL")
        nodes.first["prop1"].should_not be_nil
      end      
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