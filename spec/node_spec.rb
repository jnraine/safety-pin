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
  
  context "#session" do
    it "should return a session" do
      JCR::Node.find("/content").session.should be_a(Java::JavaxJcr::Session)
    end
    
    it "should cache session in an instance variable" do
      node = JCR::Node.find("/content")
      node.session
      node.instance_eval { @session }.should be_a(Java::JavaxJcr::Session)
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
          JCR::Node.create("/content/foo")
          node.child("content/foo").name.should eql("foo")
          JCR::Node.find("/content/foo").destroy
        end
      end
      
      context "that doesn't exist" do
        it "should return nil" do
          node.child("foobarbaz").should be_nil
        end
      end
    end
  end
  
  context "#name" do
    it "should return a string name" do
      JCR::Node.find("/content").name.should eql("content")
    end
  end
  
  describe "#save" do
    context "on an existing node with changes" do
      before do 
        @node = JCR::Node.create("/content/foo")
        @node["bar"] = "baz"
      end
      
      after { @node.destroy }
    
      it "should save the changes to the JCR" do
        @node.save
        @node.reload
        @node["bar"].should eql("baz")
      end
  
      it "should return true if the save was successful" do
        save_successful = @node.save
        (save_successful and not @node.changed?).should be_true
      end
    end
    
    context "on a new node" do      
      it "should save the node" do
        node = JCR::Node.build("/content/foo")
        node.save.should be_true
        node.destroy
      end
      
      it "should save changes in parent node" do
        parent_node = JCR::Node.create("/content/foo")
        node = JCR::Node.build("/content/foo/bar")
        parent_node["baz"] = "qux"
        parent_node.should be_changed
        node.save
        parent_node.should_not be_changed
        node.destroy
        parent_node.destroy
      end
    end
  end
  
  describe "#read_attribute" do
    context "on an existing node" do
      before { @node = JCR::Node.create("/content/foo") }
      after { @node.destroy }
    
      it "should return the string value of a string property" do
        @node["foo"] = "bar"
        @node.read_attribute("foo").should eql("bar")
      end
    
      it "should return the boolean value of a boolean property" do
        @node["foo"] = true
        @node.read_attribute("foo").should eql(true)
      end
    
      it "should return the double value of a double (or Ruby float) property" do
        @node["foo"] = 3.14
        @node.read_attribute("foo").should eql(3.14)
      end
    
      it "should return the long value of a long (or Ruby Fixnum) property" do
        @node["foo"] = 42
        @node.read_attribute("foo").should eql(42)
      end
    
      it "should return the time value of a date property" do
        time = Time.now
        @node["foo"] = time
        @node.read_attribute("foo").to_s.should eql(time.to_s)
      end
      
      context "given a multi-value property" do
        it "should return an array of values" do
          @node["foo"] = ["one", "two"]
          @node.read_attribute("foo").should eql(["one", "two"])
        end
      end
    end
    
    it "should return the string value of a name property" do
      JCR::Node.find("/")["jcr:primaryType"].should eql("rep:root")
    end
    
    it "should throw an exception when accessing a non-existent (nil) property" do
      lambda { JCR::Node.build("/content/foo").read_attribute("foo-bar-baz") }.should raise_error(JCR::NilPropertyError)
    end
  end
  
  context "#write_attribute" do
    before { @node = JCR::Node.create("/content/foo") }
    after { @node.destroy }
     
    context "given a single value" do
      it "should set a string property value" do
        @node.write_attribute("foo", "bar")
        @node.save
        @node.reload
        @node["foo"].should eql("bar")
      end
    
      context "given a Time object" do
        it "should set a date property value" do
          time = Time.now
          @node.write_attribute("foo", time)
          @node.save
          @node.reload
          @node["foo"].to_s.should eql(time.to_s)
        end
      end
    end

    context "given an array of values" do
      context "of the same type" do
        it "should set a multi-value string array" do
          @node.write_attribute("foo", ["one", "two"])
          @node.save
          @node.reload
          @node["foo"].should eql(["one", "two"])
        end
      end
    end
  end
  
  context "#reload" do
    before { @node = JCR::Node.create("/content/foo") }
    after { @node.destroy }
    
    it "should discard pending changes" do
      @node["foo"] = "bar"
      @node.reload
      lambda { @node.read_attribute("foo") }.should raise_error(JCR::NilPropertyError)
    end
    
    it "should not discard changes for another node" do
      @node["bar"] = "baz"
      another_node = JCR::Node.find("/content")
      another_node["bar"] = "baz"
      @node.reload
      lambda { @node["bar"] }.should raise_error(JCR::NilPropertyError)
      another_node["bar"].should eql("baz")
    end
  end
  
  describe "#[]" do
    it "should return the value of a given property name" do
      node = JCR::Node.create("/content/foo")
      node.write_attribute("bar","baz")
      node.save
      node["bar"].should eql("baz")
      node.destroy
    end
  end
  
  describe "#[]=" do    
    it "should set the value of a given property name" do
      node = JCR::Node.create("/content/foo")
      node.write_attribute("bar","baz")
      node["bar"] = "qux"
      node["bar"].should eql("qux")
      node.destroy
    end
  end
  
  context "#changed?" do
    let(:node) { JCR::Node.find("/content") }

    it "should return false if the node does not have unsaved changes" do
      node.should_not be_changed
    end
    
    it "should return true if the node has unsaved changes" do
      node["foo"] = "bar"
      node.should be_changed
    end
  end
  
  context "#new?" do
    it "should return true if node has never been saved to JCR" do
      JCR::Node.build("/content/foo").should be_new
    end
    
    it "should return false if node has been saved to JCR" do
      JCR::Node.find("/content").should_not be_new
    end
  end

  context "#properties" do
    it "should return hash of all properties" do
      JCR::Node.find("/").properties.should eql({"jcr:primaryType"=>"rep:root", "sling:target"=>"/index.html", "sling:resourceType"=>"sling:redirect", "jcr:mixinTypes"=>["rep:AccessControllable"]})
    end
  end

  describe ".build" do
    context "given an absolute path" do
      it "should build and return a property-less, unsaved nt:unstructured child node" do
        node = JCR::Node.build("/content/foo")
        node.should be_new
        node.properties.should eql({"jcr:primaryType" => "nt:unstructured"})
      end
      
      context "and a node type string" do
        it "should create an unsaved node of the given type" do
          node = JCR::Node.build("/content/foo", "nt:folder")
          node.should be_new
          node["jcr:primaryType"].should eql("nt:folder")
        end
      end

      context "that already exists" do
        it "should raise an error" do
          lambda { JCR::Node.build("/content") }.should raise_error(JCR::NodeError)
        end
      end
    end
    
    context "given an absolute path with a non-existent parent node" do
      it "should raise an error" do
        lambda { JCR::Node.build("/content/foo/bar/baz") }.should raise_error(JCR::NodeError)
      end
    end
    
    context "given a relative path" do
      it "should raise an error" do
        lambda { JCR::Node.build("content/foo") }.should raise_error(ArgumentError)
      end
    end
  end
  
  describe ".create" do
    context "given a path" do
      it "should build and save a node" do
        node = JCR::Node.create("/content/foo")
        node.should be_a(JCR::Node)
        node.destroy
      end
    end
    
    context "given a path and a node type" do
      it "should build and save a node of the specified type" do
        node = JCR::Node.create("/content/foo", "nt:folder")
        JCR::Node.find("/content/foo").should_not be_nil
        node.destroy
      end
    end
  end
  
  context "#value_factory" do
    it "should return a value factory instance" do
      JCR::Node.find("/content").value_factory.should be_a(Java::JavaxJcr::ValueFactory)
    end
  end
  
  describe "#property_is_multi_valued" do
    it "should return true if property is multi-valued" do
      node = JCR::Node.create("/content/foo")
      node["bar"] = ["baz", "qux"]
      node.save
      property = node.j_node.get_property("bar")
      node.property_is_multi_valued?(property).should be_true
      node.destroy
    end
    
    it "should return false if property is not multi-valued" do
      node = JCR::Node.create("/content/foo")
      node["bar"] = "baz"
      node.save
      property = node.j_node.get_property("bar")
      node.property_is_multi_valued?(property).should be_false
      node.destroy
    end
  end
  
  describe "#destroy" do
    it "should remove node from JCR" do
      path = "/content/foo"
      node = JCR::Node.create(path)
      node.destroy
      JCR::Node.find(path).should be_nil
    end
    
    it "should save changes in parent node" do
      parent_node = JCR::Node.create("/content/foo")
      node = JCR::Node.create("/content/foo/bar")
      parent_node["baz"] = "qux"
      parent_node.should be_changed
      node.destroy
      parent_node.should_not be_changed
      parent_node.destroy
    end
  end
end