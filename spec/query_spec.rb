require 'spec_helper.rb'

describe SafetyPin::Query do  
  let(:query) { SafetyPin::Query.new }

  describe ".execute" do
    before do
      @node = SafetyPin::Node.create("/content/foo")
      @node["bar"] = "baz"
      @node.save
    end
    
    after { @node.destroy }
    
    it "should lookup nodes given a valid JCR-SQL2 query string" do
      nodes = SafetyPin::Query.execute("SELECT * FROM [nt:base] WHERE [nt:base].bar IS NOT NULL")
      nodes.first["bar"].should_not be_nil
    end
  end
  
  describe "#sql" do
    it "should compile a default query string to return all nodes" do
      query.sql.should eql("SELECT * FROM [nt:base]")
    end
    
    it "should compile a query string to search for nodes of a specific type" do
      query.type("cq:Page")
      query.sql.should eql("SELECT * FROM [cq:Page]")
    end
    
    it "should compile a query string to search for a node with a property and value" do
      query.where("foo" => "bar")
      query.sql.should eql("SELECT * FROM [nt:base] WHERE [foo] = 'bar'")
    end
    
    it "should compile a query string to search for a node with multiple properties and values" do
      query.where("foo" => "bar", "baz" => "quux")
      query.sql.should eql("SELECT * FROM [nt:base] WHERE [foo] = 'bar' AND [baz] = 'quux'")
    end
    
    it "should compile a query string to search for a node within a path" do
      query.within("/content/")
      query.sql.should eql("SELECT * FROM [nt:base] WHERE [jcr:path] LIKE '/content/%'")
    end
    
    it "should compile a query string to search a node within multiple nodes" do
      
    end
  end
  
  describe "#within" do
    context "given string paths" do
      it "should append to @within instance variable" do
        query.within("/foo")
        query.within("/bar")
        query.instance_eval { @within }.should eql(["/foo", "/bar"])
      end
    end
    
    context "given an array of string paths" do
      it "should append to @within instance variable" do
        query.within("/foo")
        query.within(["/bar", "/baz"])
        query.instance_eval { @within }.should eql(["/foo", "/bar", "/baz"])
      end
    end
    
    context "given an invalid argument" do
      it "should ignore it" do
        query.within("/foo")
        query.within(nil)
        query.instance_eval { @within }.should eql(["/foo"])
      end
    end
  end
  
  describe "#where" do
    it "should append to where_conditions" do
      query.where("foo" => "bar")
      query.where("baz" => "quux")
      query.where_conditions.should eql([SafetyPin::Query::WhereCondition.new("foo", "bar"), SafetyPin::Query::WhereCondition.new("baz", "quux")])
    end
  end
  
  describe "#type" do
    it "should set the node type" do
      query = SafetyPin::Query.new
      query.type("cq:Page")
      query.instance_eval { @type }.should eql("cq:Page")
    end
  end
  
  describe "#where_conditions" do
    it "should return an empty array by default" do
      query.where_conditions.should eql([])
    end
  end
  
  # 
  # it "should query for nodes beneath a specific path" do
  #   pending
  #   nodes = SafetyPin::Query.path("/content/sfu")
  # end
  # 
  # it "should query for nodes with a specific property" do
  #   pending
  #   nodes = SafetyPin::Query.where("cq:Template" => "/apps/sfu/templates/basicpage")
  # end
  # 
  # it "should chain together query methods to build a query" do
  #   pending
  #   nodes = SafetyPin::Query.path("/content").type("nt:unstructured").where("jcr:title" => "Open House")
  # end
end