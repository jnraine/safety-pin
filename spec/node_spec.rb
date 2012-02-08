require 'spec_helper.rb'

describe JCR::Node do
  before do    
    JCR.login(:hostname => "http://localhost:4502", :username => "admin", :password => "admin")
  end
  
  context ".find" do
    it "can retrieve a node given a path" do
      node = JCR::Node.find("/content")
      node.should be_a(JCR::Node)
      node.path.should eql("/content")
    end
    
    it "complains if the path isn't an absolute path" do
      lambda { node = JCR::Node.find("content") }.should raise_exception(ArgumentError)
    end
  end
  
  context ".session" do
    it "should return a session" do
      JCR::Node.session.should be_a(Java::JavaxJcr::Session)
    end
  end
  
  context "#children" do
    it "should return an array of child nodes" do
      node = JCR::Node.find("/content")
      node.children.first.should be_a(JCR::Node)
    end
  end
  
  context "#child" do
    context "given a node name" do
      context "that exists" do
        it "should return a child node with a matching name" do      
          node = JCR::Node.find("/")
          child_node = node.child("content")
          child_node.should be_a(JCR::Node)
          child_node.name.should eql("content")
        end
      end
      
      context "that doesn't exist" do
        it "should return nil" do      
          node = JCR::Node.find("/")
          child_node = node.child("foobarbazcontent")
          child_node.should be_nil
        end
      end
    end
  end
  
  context "#name" do
    it "should return a string name" do
      node = JCR::Node.find("/content")
      node.name.should eql("content")
    end
  end
end