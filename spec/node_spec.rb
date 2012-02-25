require 'spec_helper.rb'

describe JCR::Node do
  before(:all) do
    JCR.login(:hostname => "http://localhost:4502", :username => "admin", :password => "admin")
  end
  
  before do
    JCR.session.refresh(false)
  end
  
  after(:all) do
    JCR.logout
  end
  
  context ".find" do
    context "given a node name" do
      context "that exists" do
        it "should return a node with a matching path" do
          JCR::Node.find("/content").path.should eql("/content")
        end
      end
    
      context "that doesn't exist" do
        it "should return nil" do
          JCR::Node.find("/foo/bar/baz").should be_nil
        end
      end
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
      JCR::Node.find("/content").children.first.should be_a(JCR::Node)
    end
  end
  
  context "#child" do
    context "given a node name" do
      let(:node) { JCR::Node.find("/") }
      
      context "that exists" do
        it "should return a child node with a matching name" do
          node.child("content").name.should eql("content")
        end
        
        it "should return a grandchild node given a relative path" do
          node.child("content/sfu").name.should eql("sfu")
        end
      end
      
      context "that doesn't exist" do
        it "should return nil" do
          node.child("foobarbazcontent").should be_nil
        end
      end
    end
  end
  
  context "#name" do
    it "should return a string name" do
      JCR::Node.find("/content").name.should eql("content")
    end
  end
  
  context "#save" do
    let(:random_value) { Time.now.to_i.to_s }
    let(:node) { JCR::Node.find("/content/sfu/jcr:content/test") }
    
    it "should save the changes to the JCR" do
      node["save-me"] = random_value
      node.save
      node.reload
      node["save-me"].should eql(random_value)
    end
    
    it "should return true if the save was successful" do
      node["save-me"] = random_value
      save_successful = node.save
      node.reload
      (save_successful and not node.changed?).should be_true
    end
  end
  
  context "#read_attribute" do
    let(:node) { JCR::Node.find("/content/sfu/jcr:content/test") }

    it "should return the string value of a string property" do
      node["prop1"] = "Foo"
      node.read_attribute("prop1").should eql("Foo")
    end
    
    it "should return the boolean value of a boolean property" do
      node["prop-bool"] = true
      node.read_attribute("prop-bool").should eql(true)
    end
    
    it "should return the double value of a double (or Ruby float) property" do
      node["prop-double"] = 3.14
      node.read_attribute("prop-double").should eql(3.14)
    end
    
    it "should return the long value of a long (or Ruby Fixnum) property" do
      node["prop-long"] = 42
      node.read_attribute("prop-long").should eql(42)
    end
    
    it "should return the time value of a date property" do
      time = Time.now
      node["prop-date"] = time
      node.read_attribute("prop-date").to_s.should eql(time.to_s)
    end
    
    it "should throw an exception when accessing a non-existent (nil) property" do
      lambda { node.read_attribute("foo-bar-baz") }.should raise_error(JCR::NilPropertyError)
    end
  end
  
  context "#write_attribute" do
    let(:node) { JCR::Node.find("/content/sfu/jcr:content/test") }
    it "should set a string property value" do
      node.write_attribute("prop1", "Foo")
      node.save
      node.reload
      node["prop1"].should eql("Foo")
    end
    
    context "given a Time object" do
      it "should set a date property value" do
        time = Time.now
        node.write_attribute("prop-date", time)
        node.save
        node.reload
        node["prop-date"].to_s.should eql(time.to_s)
      end
    end
  end
  
  context "#reload" do
    let(:node) { JCR::Node.find("/content/sfu/jcr:content/test") }
    let(:unique_name) { Time.now.to_i.to_s }

    it "should discard pending changes" do
      node["never-saved-prop"] = "Foo"
      node.reload
      lambda { node.read_attribute("never-saved-prop") }.should raise_error(JCR::NilPropertyError)
    end
    
    it "should not discard changes for another node" do
      node[unique_name] = "bar"
      another_node = JCR::Node.find("/content")
      another_node[unique_name] = "baz"
      node.reload
      lambda { node[unique_name] }.should raise_error(JCR::NilPropertyError)
      another_node[unique_name].should eql("baz")
    end
  end
  
  context "#[]" do
    it "should return the value of a given property name" do
      node = JCR::Node.find("/content/sfu/jcr:content/test")
      node.write_attribute("prop1","Foo")
      node.save
      node["prop1"].should eql("Foo")
    end
  end
  
  context "#[]=" do
    let(:original_value) { "Foo" }
    let(:random_value) { Time.now.to_i.to_s }
    
    it "should set the value of a given property name" do
      node = JCR::Node.find("/content/sfu/jcr:content/test")
      node.write_attribute("prop1","Foo")
      node["prop1"] = random_value
      node["prop1"].should eql(random_value)
    end
  end
  
  context "#changed?" do
    let(:node) { JCR::Node.find("/content") }
    it "should return false if the node does not have unsaved changes" do
      node.should_not be_changed
    end
    
    it "should return true if the node has unsaved changes" do
      node["prop1"] = "Foo"
      node.should be_changed
    end
  end
  
  context "#new?" do
    it "should return true if node has never been saved to JCR" do
      new_node = JCR::Node.new(JCR::Node.find("/content").j_node.add_node("foo-bar-baz"))
      new_node.should be_new
    end
    
    it "should return false if node has been saved to JCR" do
      JCR::Node.find("/content").should_not be_new
    end
  end

  context "#properties" do
    it "should return hash of all properties" do
      JCR::Node.find("/content").properties.should eql({})
    end
  end

  context "#create!" do
    let(:node) { JCR::Node.find("/content") }
    
    context "given no arguments" do
      it "should build and return a property-less, unsaved nt:unstructured child node" do
        # child_node = node.build("/content/foo")
        # child_node.should be_new
        # child_node.attributes.should eql({})
      end
    end
  end
end