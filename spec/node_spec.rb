require 'spec_helper.rb'

describe SafetyPin::Node do
  before(:all) do
    SafetyPin::JCR.login(:hostname => "http://localhost:4502", :username => "admin", :password => "admin")
  end
  
  before do
    SafetyPin::JCR.session.refresh(false)
  end
  
  after(:all) do
    SafetyPin::JCR.logout
  end
  
  describe ".find" do
    context "given a node name" do
      context "that exists" do
        it "should return a node with a matching path" do
          SafetyPin::Node.find("/content").path.should eql("/content")
        end
      end
    
      context "that doesn't exist" do
        it "should return nil" do
          SafetyPin::Node.find("/foo/bar/baz").should be_nil
        end
      end
    end
    
    it "complains if the path isn't an absolute path" do
      lambda { node = SafetyPin::Node.find("content") }.should raise_exception(ArgumentError)
    end
  end
  
  describe ".find_or_create" do    
    context "given a node path that exists" do
      it "should return the node at that path" do
        SafetyPin::Node.create("/content/foo")
        SafetyPin::Node.find_or_create("/content/foo").path.should eql "/content/foo"
        SafetyPin::Node.find("/content/foo").destroy
      end
    end
    
    context "give a node path that doesn't exist" do
      it "should create a node at the path and return it" do
        SafetyPin::Node.find("/content/foo").should be_nil
        SafetyPin::Node.find_or_create("/content/foo").path.should eql "/content/foo"
        SafetyPin::Node.find("/content/foo").destroy
      end
    end
  end
  
  describe ".session" do
    it "should return a session" do
      SafetyPin::Node.session.should be_a(Java::JavaxJcr::Session)
    end
  end
  
  describe "#session" do
    it "should return a session" do
      SafetyPin::Node.find("/content").session.should be_a(Java::JavaxJcr::Session)
    end
    
    it "should cache session in an instance variable" do
      node = SafetyPin::Node.find("/content")
      node.session
      node.instance_eval { @session }.should be_a(Java::JavaxJcr::Session)
    end
  end
  
  describe "#children" do
    it "should return an array of child nodes" do
      SafetyPin::Node.find("/content").children.first.should be_a(SafetyPin::Node)
    end
  end
  
  describe "#child" do
    context "given a node name" do
      let(:node) { SafetyPin::Node.find("/") }
      
      context "that exists" do
        it "should return a child node with a matching name" do
          node.child("content").name.should eql("content")
        end
        
        it "should return a grandchild node given a relative path" do
          SafetyPin::Node.create("/content/foo")
          node.child("content/foo").name.should eql("foo")
          SafetyPin::Node.find("/content/foo").destroy
        end
      end
      
      context "that doesn't exist" do
        it "should return nil" do
          node.child("foobarbaz").should be_nil
        end
      end
    end
  end
  
  describe "#find_or_create_child" do
    let(:parent) { SafetyPin::Node.create("/content/foo") }
    
    context "an existing node path" do
      it "should return the child node" do
        parent.create("bar")
        parent.find_or_create("bar").path.should eql "/content/foo/bar"
      end
    end
    
    context "a non-existing node path" do
      it "should create a node and return it" do
        parent.find_or_create("bar").path.should eql "/content/foo/bar"
      end
    end
  end
  
  describe "#name" do
    it "should return a string name" do
      SafetyPin::Node.find("/content").name.should eql("content")
    end
  end
  
  describe "#save" do
    context "on an existing node with changes" do
      before do 
        @node = SafetyPin::Node.create("/content/foo")
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
        node = SafetyPin::Node.build("/content/foo")
        node.save.should be_true
        node.destroy
      end
      
      it "should save changes in parent node" do
        parent_node = SafetyPin::Node.create("/content/foo")
        node = SafetyPin::Node.build("/content/foo/bar")
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
      before { @node = SafetyPin::Node.create("/content/foo") }
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
      
      context "given a non-string name" do
        it "should co-erce the name into a string and retrieve the property" do
          @node["foo"] = "bar"
          @node.read_attribute(:foo).should eql("bar")
        end
      end
    end
    
    it "should return the string value of a name property" do
      SafetyPin::Node.find("/")["jcr:primaryType"].should eql("rep:root")
    end
    
    it "should throw an exception when accessing a non-existent (nil) property" do
      lambda { SafetyPin::Node.build("/content/foo").read_attribute("foo-bar-baz") }.should raise_error(SafetyPin::NilPropertyError)
    end
  end
  
  context "#write_attribute" do
    before { @node = SafetyPin::Node.create("/content/foo") }
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
      
      context "given a non-string name" do
        it "should co-erce name into string before setting property" do          
          @node.write_attribute(:foo, "bar")
          @node.save
          @node.reload
          @node["foo"].should eql("bar")
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
    
    context "given a null value" do
      it "should remove the property" do
        @node["foo"] = "bar"
        @node.write_attribute("foo", nil)
        lambda { @node["foo"] }.should raise_error(SafetyPin::NilPropertyError)
      end
      
      context "given a non-existent property and a null value" do
        it "should return nil" do
          @node.write_attribute("foo", nil).should be_nil
        end
      end
    end

    context "changing jcr:primaryType property" do
      it "should raise an error" do
       lambda { @node.write_attribute("jcr:primaryType", "nt:folder") }.should raise_error(SafetyPin::PropertyError)
      end
    end
  end
  
  context "#reload" do
    before { @node = SafetyPin::Node.create("/content/foo") }
    after { @node.destroy }
    
    it "should discard pending changes" do
      @node["foo"] = "bar"
      @node.reload
      lambda { @node.read_attribute("foo") }.should raise_error(SafetyPin::NilPropertyError)
    end
    
    it "should not discard changes for another node" do
      @node["bar"] = "baz"
      another_node = SafetyPin::Node.find("/content")
      another_node["bar"] = "baz"
      @node.reload
      lambda { @node["bar"] }.should raise_error(SafetyPin::NilPropertyError)
      another_node["bar"].should eql("baz")
    end
  end
  
  describe "#[]" do
    it "should return the value of a given property name" do
      node = SafetyPin::Node.create("/content/foo")
      node.write_attribute("bar","baz")
      node.save
      node["bar"].should eql("baz")
      node.destroy
    end
  end
  
  describe "#[]=" do    
    it "should set the value of a given property name" do
      node = SafetyPin::Node.create("/content/foo")
      node.write_attribute("bar","baz")
      node["bar"] = "qux"
      node["bar"].should eql("qux")
      node.destroy
    end
  end
  
  context "#changed?" do
    let(:node) { SafetyPin::Node.find("/content") }

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
      SafetyPin::Node.build("/content/foo").should be_new
    end
    
    it "should return false if node has been saved to JCR" do
      SafetyPin::Node.find("/content").should_not be_new
    end
  end

  describe "#properties" do
    it "should return hash of all unprotected properties" do
      SafetyPin::Node.find("/").properties.should eql({"sling:target"=>"/index.html", "sling:resourceType"=>"sling:redirect"})
    end
  end
  
  describe "#properties=" do
    before { @node = SafetyPin::Node.create("/content/foo") }
    after  { @node.destroy }
    
    it "should set the properties of a node" do
      @node.properties = {"foo" => "bar"}
      @node.properties.should eql({"foo" => "bar"})
    end
    
    it "should set unset properties not specified in hash" do
      @node["foo"] = "bar"
      @node.properties = {"baz" => "qux"}
      @node.properties.should eql({"baz" => "qux"})
    end
  end
  
  describe "#protected_properties" do
    it "should return hash of all protected properties" do
      SafetyPin::Node.find("/").protected_properties.should eql({"jcr:primaryType"=>"rep:root", "jcr:mixinTypes"=>["rep:AccessControllable", "rep:RepoAccessControllable"]})
    end
  end
  
  describe "#mixin_types" do
    before do
      @node = SafetyPin::Node.create("/content/foo")
      @node.j_node.add_mixin("mix:created")
      @node.save
    end
    
    after  { @node.destroy }
  
    it "should return the mixin types of a node" do
      @node.mixin_types.should eql(["mix:created"])
    end
  end
  
  describe "#add_mixin" do
    before { @node = SafetyPin::Node.create("/content/foo") }
    after  { @node.destroy }
  
    it "should add a mixin type to node" do
      @node.add_mixin("mix:created")
      @node.save
      @node.mixin_types.should eql(["mix:created"])
    end
    
    it "should require a save before the mixin addition is detected" do
      @node.add_mixin("mix:created")
      @node.mixin_types.should eql([])
    end
  end
  
  describe "#remove_mixin" do
    before do 
      @node = SafetyPin::Node.create("/content/foo") 
      @node.add_mixin("mix:created")
      @node.save
    end
    
    after  { @node.destroy }
    
    it "should remove a mixin type from a node" do
      @node.mixin_types.should eql(["mix:created"])
      @node.remove_mixin("mix:created")
      @node.save
      @node.mixin_types.should eql([])
    end
    
    it "should require a save before the mixin removal is detected" do
      @node.remove_mixin("mix:created")
      @node.mixin_types.should eql(["mix:created"])
      @node.reload
    end
  end

  describe ".build" do
    context "given an absolute path" do
      it "should build and return a property-less, unsaved nt:unstructured child node" do
        node = SafetyPin::Node.build("/content/foo")
        node.should be_new
        node.properties.should eql({})
      end
      
      context "and a node type string" do
        it "should create an unsaved node of the given type" do
          node = SafetyPin::Node.build("/content/foo", "nt:folder")
          node.should be_new
          node["jcr:primaryType"].should eql("nt:folder")
        end
      end

      context "that already exists" do
        it "should raise an error" do
          lambda { SafetyPin::Node.build("/content") }.should raise_error(SafetyPin::NodeError)
        end
      end
      
      it "should coerce path to a string" do
        node = SafetyPin::Node.build(Pathname("/content/foo"))
        node.should be_new
        node.properties.should eql({})
      end
    end
    
    context "given an absolute path with a non-existent parent node" do
      it "should raise an error" do
        lambda { SafetyPin::Node.build("/content/foo/bar/baz") }.should raise_error(SafetyPin::NodeError)
      end
    end
    
    context "given a relative path" do
      it "should raise an error" do
        lambda { SafetyPin::Node.build("content/foo") }.should raise_error(ArgumentError)
      end
    end
  end
  
  describe ".create" do
    context "given a path" do
      it "should build and save a node" do
        node = SafetyPin::Node.create("/content/foo")
        node.should be_a(SafetyPin::Node)
        node.destroy
      end
    end
    
    context "given a path and a node type" do
      it "should build and save a node of the specified type" do
        node = SafetyPin::Node.create("/content/foo", "nt:folder")
        SafetyPin::Node.find("/content/foo").should_not be_nil
        node.destroy
      end
    end
  end
  
  context "#value_factory" do
    it "should return a value factory instance" do
      SafetyPin::Node.find("/content").value_factory.should be_a(Java::JavaxJcr::ValueFactory)
    end
  end
  
  describe "#property_is_multi_valued" do
    it "should return true if property is multi-valued" do
      node = SafetyPin::Node.create("/content/foo")
      node["bar"] = ["baz", "qux"]
      node.save
      property = node.j_node.get_property("bar")
      node.property_is_multi_valued?(property).should be_true
      node.destroy
    end
    
    it "should return false if property is not multi-valued" do
      node = SafetyPin::Node.create("/content/foo")
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
      node = SafetyPin::Node.create(path)
      node.destroy
      SafetyPin::Node.find(path).should be_nil
    end
    
    it "should save changes in parent node" do
      parent_node = SafetyPin::Node.create("/content/foo")
      node = SafetyPin::Node.create("/content/foo/bar")
      parent_node["baz"] = "qux"
      parent_node.should be_changed
      node.destroy
      parent_node.should_not be_changed
      parent_node.destroy
    end
    
    context "when it fails" do
      before do
        @node = SafetyPin::Node.create("/content/foo")
        @node.add_mixin("mix:created")
        @node.save
      end
      
      after { @node.reload; @node.destroy }
      
      it "should raise an error" do
        @node.remove_mixin("mix:created") # make node unremoveable
        lambda { @node.destroy }.should raise_error(SafetyPin::NodeError)
      end
    end
  end
  
  describe "#primary_type" do
    before { @node = SafetyPin::Node.create("/content/foo") }
    after { @node.destroy }
    
    it "should return the primary type of the node" do
      @node.primary_type.should eql("nt:unstructured")
    end
  end
  
  describe "#create" do
    before { @node = SafetyPin::Node.create("/content/foo") }
    after { @node.destroy }
    
    it "should create a child node with a given name" do
      @node.create("bar")
      SafetyPin::Node.find("/content/foo/bar").should be_a(SafetyPin::Node)
    end
    
    it "should create a child node with a given name and node type" do
      @node.create("bar", "nt:folder")
      child_node = SafetyPin::Node.find("/content/foo/bar")
      child_node.should be_a(SafetyPin::Node)
      child_node.primary_type.should eql("nt:folder")
    end
  end
end