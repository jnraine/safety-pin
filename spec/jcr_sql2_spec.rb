require 'spec_helper.rb'

describe "JCR-SQL2 example queries" do  
  before do
    @node = SafetyPin::Node.create("/content/foo")
    @node.properties = {"bar" => "baz", "qux" => "qax"}
    @node.save
  end
  
  after { @node.destroy }
  
  it "can lookup a node based on property presence" do
    nodes = SafetyPin::Query.execute("SELECT * FROM [nt:base] WHERE [nt:base].bar IS NOT NULL")
    nodes.first["bar"].should_not be_nil
  end
  
  it "can lookup a node based on a property's value" do
    nodes = SafetyPin::Query.execute("SELECT * FROM [nt:base] WHERE bar = 'baz'")
    values = nodes.map {|e| e["bar"] }.uniq
    values.length.should eql(1)
    values.first.should eql("baz")
  end
  
  it "can lookup a node based on multiple property values" do
    nodes = SafetyPin::Query.execute("SELECT * FROM [nt:base] WHERE bar = 'baz' AND qux = 'qax'")
    bar_values = nodes.map {|e| e["bar"] }.uniq
    qux_values = nodes.map {|e| e["qux"] }.uniq
    bar_values.length.should eql(1)
    qux_values.length.should eql(1)
    bar_values.first.should eql("baz")
    qux_values.first.should eql("qax")
  end
  
  it "can lookup a node based on node name" do
    nodes = SafetyPin::Query.execute("SELECT * FROM [nt:base] WHERE NAME([nt:base]) = 'foo'")
    names = nodes.map(&:name).uniq
    names.length.should eql(1)
    names.first.should eql("foo")
  end
  
  it "can lookup a node based on a path" do
    pending "can't do this yet"
    nodes = SafetyPin::Query.execute("SELECT * FROM [nt:base] AS base WHERE base.[jcr:path] LIKE '/content/%'")
    nodes.length.should be > 0
    nodes.map(&:path).each {|name| name.starts_with?("/content").should be_true }
  end
  
  it "can lookup a node based on node type" do
    nodes = SafetyPin::Query.execute("SELECT * FROM [cq:Page]")
    nodes.first.primary_type.should eql("cq:Page")
  end
  
  it "can lookup a node based on its node super type" do
    nodes = SafetyPin::Query.execute("SELECT * FROM [rep:Authorizable]")
    primary_types = nodes.map(&:primary_type)
    primary_types.should include("rep:User")
  end
  
  # context "given some nodes and child nodes" do
  #   before do
  #     @parent2 = SafetyPin::Node.create("/content/foo2")
  #     @child1 = SafetyPin::Node.create("/content/foo2/child")
  #     @child1.properties = {"bar" => "baz", "qux" => "qax", "child" => "yes"}
  #     @child1.save
  #     @child2 = SafetyPin::Node.create("/content/foo/child")
  #     @child2.properties = {"bar" => "baz", "qux" => "qax", "child" => "yes"}
  #     @child2.save      
  #   end
  #   
  #   after do
  #     @parent2.destroy
  #   end
  #   
  #   it "can lookup a node based on nested WHERE conditions" do
  #     sql_statement = "SELECT * FROM [nt:base] 
  #                      WHERE [jcr:path] LIKE '/content/foo%'"
  #     nodes = SafetyPin::Query.execute(sql_statement)
  #     nodes.map(&:path).sort.should eql(["/content/foo/child", "/content/foo2/child"])
  #   end
  # end
end