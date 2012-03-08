require 'spec_helper.rb'

describe "JCR-SQL2 example queries" do
  before(:all) do
    JCR.login(:hostname => "http://localhost:4502", :username => "admin", :password => "admin")
  end
  
  before do
    JCR.session.refresh(false)
  end
  
  after(:all) do
    JCR.logout
  end
  
  before do
    @node = JCR::Node.create("/content/foo")
    @node["bar"] = "baz"
    @node["qux"] = "qax"
    @node.save
  end
  
  after { @node.destroy }
  
  it "can lookup a node based on property presence" do
    nodes = JCR::Query.execute("SELECT * FROM [nt:base] WHERE [nt:base].bar IS NOT NULL")
    nodes.first["bar"].should_not be_nil
  end
  
  it "can lookup a node based on a property's value" do
    nodes = JCR::Query.execute("SELECT * FROM [nt:base] WHERE bar = 'baz'")
    values = nodes.map {|e| e["bar"] }.uniq
    values.length.should eql(1)
    values.first.should eql("baz")
  end
  
  it "can lookup a node based on multiple property values" do
    nodes = JCR::Query.execute("SELECT * FROM [nt:base] WHERE bar = 'baz' AND qux = 'qax'")
    bar_values = nodes.map {|e| e["bar"] }.uniq
    qux_values = nodes.map {|e| e["qux"] }.uniq
    bar_values.length.should eql(1)
    qux_values.length.should eql(1)
    bar_values.first.should eql("baz")
    qux_values.first.should eql("qax")
  end
  
  it "can lookup a node based on node name" do
    nodes = JCR::Query.execute("SELECT * FROM [nt:base] WHERE NAME([nt:base]) = 'foo'")
    names = nodes.map(&:name).uniq
    names.length.should eql(1)
    names.first.should eql("foo")
  end
  
  it "can lookup a node based on a path" do
    nodes = JCR::Query.execute("SELECT * FROM [nt:base] WHERE [jcr:path] LIKE '/content/%'")
    nodes.map(&:path).each {|name| name.starts_with?("/content").should be_true }
  end
  
  it "can lookup a node based on node type" do
    nodes = JCR::Query.execute("SELECT * FROM [cq:Page]")
    nodes.first.primary_type.should eql("cq:Page")
  end
  
  it "can lookup a node based on its node super type" do
    nodes = JCR::Query.execute("SELECT * FROM [rep:Authorizable]")
    primary_types = nodes.map(&:primary_type)
    primary_types.should include("rep:User")
  end
end