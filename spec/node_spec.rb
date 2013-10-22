require 'spec_helper.rb'

describe SafetyPin::Node do  
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
        SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
        SafetyPin::Node.find_or_create("/content/foo").path.should eql "/content/foo"
      end
    end
    
    context "when node doesn't exist" do
      it "returns node created at path" do
        SafetyPin::Node.find("/content/foo").should be_nil
        SafetyPin::Node.find_or_create("/content/foo").path.should == "/content/foo"
      end
    end
  end

  describe ".exists?" do
    it "returns true if node exists at path" do
      SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
      SafetyPin::Node.exists?("/content/foo").should be_true
    end

    it "returns false if node does not exist" do
      SafetyPin::Node.exists?("/content/foo").should be_false
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
          SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
          node.child("content/foo").name.should eql("foo")
        end
      end

      it "should coerce non-string name to string and return child" do
        node.child(:content).name.should == "content"
      end
      
      context "that doesn't exist" do
        it "should return nil" do
          node.child("foobarbaz").should be_nil
        end
      end
    end
  end

  describe ".create_or_update" do
    let(:node_blueprint) { SafetyPin::NodeBlueprint.new(:path => "/content/foo") }

    it "calls Node.create with arg when nothing exists at path" do
      SafetyPin::Node.should_receive(:create).with(node_blueprint)
      SafetyPin::Node.create_or_update(node_blueprint)
    end

    it "calls Node.update with arg when node exists at path" do
      SafetyPin::Node.create(node_blueprint)
      SafetyPin::Node.should_receive(:update).with(node_blueprint)
      SafetyPin::Node.create_or_update(node_blueprint)
    end

    it "takes a node blueprint" do
      SafetyPin::Node.create_or_update(node_blueprint)
      SafetyPin::Node.exists?(node_blueprint.path).should be_true
    end

    it "takes an array of node blueprints" do
      node_blueprints = [node_blueprint, SafetyPin::NodeBlueprint.new(:path => "/content/foo/bar")]
      SafetyPin::Node.create_or_update(node_blueprints)
      node_blueprints.each {|node_blueprint| SafetyPin::Node.exists?(node_blueprint.path).should be_true }
    end
  end
  
  describe "#find_or_create_child" do
    let(:parent) { SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) }
    
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
        @node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
        @node["bar"] = "baz"
      end
    
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
        node = SafetyPin::Node.build(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
        node.save.should be_true
      end
      
      it "should save changes in parent node" do
        parent_node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
        node = SafetyPin::Node.build(SafetyPin::NodeBlueprint.new(:path => "/content/foo/bar"))
        parent_node["baz"] = "qux"
        parent_node.should be_changed
        node.save
        parent_node.should_not be_changed
      end
    end
  end
  
  describe "#read_attribute" do
    context "on an existing node" do
      let(:node) { SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) }
    
      it "should return the string value of a string property" do
        node["foo"] = "bar"
        node.read_attribute("foo").should eql("bar")
      end
    
      it "should return the boolean value of a boolean property" do
        node["foo"] = true
        node.read_attribute("foo").should eql(true)
      end
    
      it "should return the double value of a double (or Ruby float) property" do
        node["foo"] = 3.14
        node.read_attribute("foo").should eql(3.14)
      end
    
      it "should return the long value of a long (or Ruby Fixnum) property" do
        node["foo"] = 42
        node.read_attribute("foo").should eql(42)
      end
    
      it "should return the time value of a date property" do
        time = Time.now
        node["foo"] = time
        node.read_attribute("foo").to_s.should eql(time.to_s)
      end
      
      context "given a multi-value property" do
        it "should return an array of values" do
          node["foo"] = ["one", "two"]
          node.read_attribute("foo").should eql(["one", "two"])
        end
      end
      
      context "given a non-string name" do
        it "should co-erce the name into a string and retrieve the property" do
          node["foo"] = "bar"
          node.read_attribute(:foo).should eql("bar")
        end
      end
    end
    
    it "should return the string value of a name property" do
      SafetyPin::Node.find("/")["jcr:primaryType"].should eql("rep:root")
    end
    
    it "should throw an exception when accessing a non-existent (nil) property" do
      lambda { SafetyPin::Node.build(SafetyPin::NodeBlueprint.new(:path => "/content/foo")).read_attribute("foo-bar-baz") }.should raise_error(SafetyPin::NilPropertyError)
    end
  end
  
  context "#write_attribute" do
    let(:node) { SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) }
     
    context "given a single value" do
      it "should set a string property value" do
        node.write_attribute("foo", "bar")
        node.save
        node.reload
        node["foo"].should eql("bar")
      end
    
      context "given a Time object value" do
        it "should set a date property value" do
          time = Time.now
          node.write_attribute("foo", time)
          node.save
          node.reload
          node["foo"].to_s.should eql(time.to_s)
        end
      end

      context "given a symbol value" do
        it "coerces value to string" do
          node.write_attribute("foo", :bar)
          node["foo"].should == "bar"
        end
      end

      context "given a pathname value" do
        it "coers value to string" do
          node.write_attribute("foo", Pathname("/content/foo"))
          node["foo"].should == "/content/foo"
        end
      end

      context "given another supported value" do
        it "sets the property" do
          node.write_attribute("foo", 1)
          node["foo"].should == 1
          node.write_attribute("foo", 1.1)
          node["foo"].should == 1.1
          node.write_attribute("foo", true)
          node["foo"].should == true
          node.write_attribute("foo", "bar")
          node["foo"].should == "bar"
        end
      end

      context "given an unsupported value" do
        it "raises an error" do
          lambda { node.write_attribute("foo", {unsupported: :value_type}) }.should raise_error(SafetyPin::PropertyTypeError)
        end
      end
      
      context "given a non-string name" do
        it "should co-erce name into string before setting property" do          
          node.write_attribute(:foo, "bar")
          node.save
          node.reload
          node["foo"].should eql("bar")
        end
      end

      context "when changing a property from a single value to a multivalue" do
        it "doesn't throw exceptions" do
          node.write_attribute(:foo, "bar")
          node.save
          node.reload
          node.write_attribute(:foo, ["bar"])
          node.save
          node.reload
          node["foo"].should == ["bar"]
        end
      end

      context "when changing a property from a multi value to a single value" do
        it "works as expected" do
          node.write_attribute("foo", ["bar"])
          node.save
          node.reload
          node.write_attribute("foo", "not bar")
          node.save
          node.reload
          node["foo"].should == "not bar"
        end

        it "removes node when given nil" do
          node.write_attribute("foo", ["bar"])
          node.save
          node.reload
          node.write_attribute("foo", nil)
          node.save
          node.reload
          node.properties.keys.should_not include("foo")
        end
      end
    end

    context "given an array of values" do
      context "of the same type" do
        it "should set a multi-value string array" do
          node.write_attribute("foo", ["one", "two"])
          node.save
          node.reload
          node["foo"].should eql(["one", "two"])
        end
      end
    end
    
    context "given a null value" do
      it "should remove the property" do
        node["foo"] = "bar"
        node.write_attribute("foo", nil)
        lambda { node["foo"] }.should raise_error(SafetyPin::NilPropertyError)
      end
      
      context "given a non-existent property and a null value" do
        it "should return nil" do
          node.write_attribute("foo", nil).should be_nil
        end
      end
    end

    context "changing jcr:primaryType property" do
      it "should raise an error" do
       lambda { node.write_attribute("jcr:primaryType", "nt:folder") }.should raise_error(SafetyPin::PropertyError)
      end
    end
  end
  
  context "#reload" do
    let(:node) { SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) }
    
    it "should discard pending changes" do
      node["foo"] = "bar"
      node.reload
      lambda { node.read_attribute("foo") }.should raise_error(SafetyPin::NilPropertyError)
    end
    
    it "should not discard changes for another node" do
      node["bar"] = "baz"
      another_node = SafetyPin::Node.find("/content")
      another_node["bar"] = "baz"
      node.reload
      lambda { node["bar"] }.should raise_error(SafetyPin::NilPropertyError)
      another_node["bar"].should eql("baz")
    end
  end
  
  describe "#[]" do
    it "should return the value of a given property name" do
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
      node.write_attribute("bar","baz")
      node.save
      node["bar"].should eql("baz")
    end
  end
  
  describe "#[]=" do    
    it "should set the value of a given property name" do
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
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
      SafetyPin::Node.build(SafetyPin::NodeBlueprint.new(:path => "/content/foo")).should be_new
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
    let(:node) { SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) }
    
    it "should set the properties of a node" do
      node.properties = {"foo" => "bar"}
      node.properties.should == {"foo" => "bar"}
    end
    
    it "should set unset properties not specified in hash" do
      node["foo"] = "bar"
      node.properties = {"baz" => "qux"}
      node.properties.should eql({"baz" => "qux"})
    end

    it "creates child nodes for node blueprints" do
      node_blueprint = SafetyPin::NodeBlueprint.new(:path => "/this/path/gets/thrown/away", 
                                                    :primary_type => "sling:OrderedFolder", 
                                                    :properties => {"bar" => "baz"})
      node.properties = {"foo" => node_blueprint}
      node.child("foo").properties.should == {"bar" => "baz"}
      node.child("foo").primary_type.should == "sling:OrderedFolder"
    end

    xit "updates child nodes when they already exist" do
      # Create /content/foo/bar and /content/foo/bar/baz
      node.create(:bar, "nt:unstructured", {"bar" => "baz"})
      node.child(:bar).create(:baz)
      node.child(:bar).child(:baz).path.should == "/content/foo/bar/baz"
      # Update /content/foo/bar by updating /content/foo properties
      node.properties = {bar: SafetyPin::NodeBlueprint.new(:path => "/this/path/gets/thrown/away", :primary_type => "sling:OrderedFolder", :properties => {"updated" => "props"})}
      node.child(:bar).properties.should == {"updated" => "props"}
      node.child(:bar).primary_type.should == "sling:OrderedFolder"
      node.child(:bar).child(:baz).path.should == "/content/foo/bar/baz"
    end
  end
  
  describe "#protected_properties" do
    it "should return hash of all protected properties" do
      SafetyPin::Node.find("/").protected_properties.should eql({"jcr:primaryType"=>"rep:root", "jcr:mixinTypes"=>["rep:AccessControllable", "rep:RepoAccessControllable"]})
    end
  end
  
  describe "#mixin_types" do
    it "should return the mixin types of a node" do
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
      node.j_node.add_mixin("mix:created")
      node.save
      node.mixin_types.should eql(["mix:created"])
    end
  end
  
  describe "#add_mixin" do
    let(:node) { SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) }
  
    it "should add a mixin type to node" do
      node.add_mixin("mix:created")
      node.save
      node.mixin_types.should eql(["mix:created"])
    end
    
    it "should require a save before the mixin addition is detected" do
      node.add_mixin("mix:created")
      node.mixin_types.should eql([])
    end
  end
  
  describe "#remove_mixin" do
    let(:node) do 
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) 
      node.add_mixin("mix:created")
      node.save
      node
    end
    
    it "should remove a mixin type from a node" do
      node.mixin_types.should eql(["mix:created"])
      node.remove_mixin("mix:created")
      node.save
      node.mixin_types.should eql([])
    end
    
    it "should require a save before the mixin removal is detected" do
      node.remove_mixin("mix:created")
      node.mixin_types.should eql(["mix:created"])
      node.reload
    end
  end

  describe ".update" do
    let(:node) do 
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
      node.save
      node
    end

    it "updates a nodes properties" do
      SafetyPin::Node.update(SafetyPin::NodeBlueprint.new(:path => node.path, :properties => {"foo" => "barbazbuzzzzz"}))
      SafetyPin::Node.find(node.path).properties.should == {"foo" => "barbazbuzzzzz"}
    end

    it "preserves node children" do
      node.create(:bar)
      SafetyPin::Node.update(SafetyPin::NodeBlueprint.new(:path => node.path, :primary_type => "sling:OrderedFolder", :properties => {"foo" => "bar"}))
      SafetyPin::Node.exists?("/content/foo/bar").should be_true
    end

    it "modifies the primary type" do
      SafetyPin::Node.update(SafetyPin::NodeBlueprint.new(:path => node.path, :primary_type => "sling:OrderedFolder"))
      SafetyPin::Node.find(node.path).primary_type.should == "sling:OrderedFolder"
    end
  end

  describe "#primary_type=" do
    let(:node) do 
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
      node.save
      node
    end

    it "sets the primary type" do
      node.primary_type.should == "nt:unstructured"
      node.primary_type = "sling:OrderedFolder"
      node.save
      SafetyPin::Node.find(node.path).primary_type.should == "sling:OrderedFolder"
    end
  end

  describe ".build" do
    it "returns an unsaved node at path of a specified type with properties set" do
      node = SafetyPin::Node.build(SafetyPin::NodeBlueprint.new(:path => "/content/foo", :primary_type => "sling:OrderedFolder", :properties => {"foo" => "bar"}))
      node.should be_new
      node.primary_type.should == "sling:OrderedFolder"
      node.properties.should == {"foo" => "bar"}
    end

    it "complains when the nodes already exists" do
      node_blueprint = SafetyPin::NodeBlueprint.new(:path => "/content/foo")
      SafetyPin::Node.create(node_blueprint)
      lambda { SafetyPin::Node.build(node_blueprint) }.should raise_error(SafetyPin::NodeError)
    end

    it "complains when given a path with missing parents" do
      lambda { SafetyPin::Node.build(SafetyPin::NodeBlueprint.new(:path => "/content/foo/bar/baz/doesnt/exist")) }.should raise_error(SafetyPin::NodeError)
    end

    it "complains when given a relative path" do
      lambda { SafetyPin::Node.build(SafetyPin::NodeBlueprint.new(:path => "foo/not/absolute")) }.should raise_error(SafetyPin::NodeError)
    end

    it "complains when given nil" do
      lambda { SafetyPin::Node.build(nil) }.should raise_error(SafetyPin::NodeError)
    end
  end
  
  describe ".create" do
    it "creates a node" do
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
      node.should be_a(SafetyPin::Node)
    end
    
    it "creates a node of a specific type" do
      SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo", :primary_type => "sling:OrderedFolder"))
      SafetyPin::Node.find("/content/foo").primary_type.should == "sling:OrderedFolder"
    end
  end

  describe ".create_parents" do
    it "creates parent nodes if they do not exist" do
      SafetyPin::Node.create_parents("/content/foo/bar/baz")
      SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo/bar/baz")).should_not be_nil
    end
  end
  
  context "#value_factory" do
    it "should return a value factory instance" do
      SafetyPin::Node.find("/content").value_factory.should be_a(Java::JavaxJcr::ValueFactory)
    end
  end
  
  describe "#property_is_multi_valued" do
    it "should return true if property is multi-valued" do
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
      node["bar"] = ["baz", "qux"]
      node.save
      property = node.j_node.get_property("bar")
      node.property_is_multi_valued?(property).should be_true
    end
    
    it "should return false if property is not multi-valued" do
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
      node["bar"] = "baz"
      node.save
      property = node.j_node.get_property("bar")
      node.property_is_multi_valued?(property).should be_false
    end
  end
  
  describe "#destroy" do
    it "should remove node from JCR" do
      path = "/content/foo"
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => path))
      node.destroy
      SafetyPin::Node.find(path).should be_nil
    end
    
    it "should save changes in parent node" do
      parent_node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
      node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo/bar"))
      parent_node["baz"] = "qux"
      parent_node.should be_changed
      node.destroy
      parent_node.should_not be_changed
    end
    
    context "when it fails" do      
      it "should raise an error" do
        node = SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo"))
        node.add_mixin("mix:created")
        node.save
        node.remove_mixin("mix:created") # make node unremoveable
        lambda { node.destroy }.should raise_error(SafetyPin::NodeError)
      end
    end
  end
  
  describe "#primary_type" do
    let(:node) { SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) }
    
    it "should return the primary type of the node" do
      node.primary_type.should eql("nt:unstructured")
    end
  end
  
  describe "#build" do
    let(:node) { SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) }
    
    it "should create a child node with a given name" do
      node.build("bar").path.should == "/content/foo/bar"
    end
    
    it "should create a child node with a given name and node type" do
      child_node = node.build("bar", SafetyPin::NodeBlueprint.new(:primary_type => "nt:folder", :path => :no_path))
      child_node.should be_a(SafetyPin::Node)
      child_node.primary_type.should == "nt:folder"
    end

    it "should create a child node with a name, node type, and properties" do
      node.build("bar", SafetyPin::NodeBlueprint.new(:path => :no_path, :properties => {foo: "bar"})).properties.should == {"foo" => "bar"}
    end
  end

  describe "#create" do
    let(:node) { SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) }
    
    it "should create a child node with a given name" do
      child_node = node.create("bar")
      child_node.path.should == "/content/foo/bar"
      child_node.should_not
    end
    
    it "should create a child node with a given name and node type" do
      child_node = node.create("bar", SafetyPin::NodeBlueprint.new(:path => :no_path, :primary_type => "nt:folder"))
      child_node.should_not be_new
      child_node.primary_type.should eql("nt:folder")
    end

    it "should create a child node with a name, node type, and properties" do
      child_node = node.create("bar", SafetyPin::NodeBlueprint.new(:path => :no_path, :properties => {foo: "bar"}))
      child_node.should_not be_new
      child_node.properties.should == {"foo" => "bar"}
    end
  end

  describe "#==" do
    it "finds two nodes with the same path to be the same" do
      node1 = SafetyPin::Node.new(double(:j_node))
      node1.should_receive(:path).and_return("/content/foo")
      node2 = SafetyPin::Node.new(double(:j_node))
      node2.should_receive(:path).and_return("/content/foo")

      node1.should == node2
    end

    it "finds two nodes with different paths to be different" do
      node1 = SafetyPin::Node.new(double(:j_node))
      node1.should_receive(:path).and_return("/content/foo")
      node2 = SafetyPin::Node.new(double(:j_node))
      node2.should_receive(:path).and_return("/content/foo/bar")

      node1.should_not == node2
    end

    it "returns false when passed an object that doesn't response to path" do
      node1 = SafetyPin::Node.new(double(:j_node))
      node1.stub(:path => "foo")
      node1.should_not == Object.new
    end

    it "returns false when passed a nil object" do
      node1 = SafetyPin::Node.new(double(:j_node))
      node1.should_not == nil
    end
  end

  describe "#parent", :focus => true do
    let(:node) { SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(:path => "/content/foo")) }

    it "returns the parent node" do
      node.parent.should == SafetyPin::Node.find("/content")
    end

    it "raises an error when called on the root node" do
      expect { SafetyPin::Node.find("/").parent }.to raise_error(SafetyPin::NodeError)
    end
  end

  describe "#replace_property" do
    let(:node) do
      properties = {"bar" => "baz", "another" => "just for completeness", "barbell" => "for regex detail"}
      blueprint = SafetyPin::NodeBlueprint.new(:path => "/content/foo", properties: properties)
      SafetyPin::Node.create(blueprint)
    end

    it "requires a property name, a target regex/string, and a replacement value or block" do
      expect { node.replace_property({})                         }.to raise_error(KeyError)
      expect { node.replace_property(name: "bar")                }.to raise_error(KeyError)
      expect { node.replace_property(name: "bar", target: /baz/) }.to raise_error(KeyError)
      expect { node.replace_property(name: "bar", target: /baz/, replacement: "NOT BAZ") }.to_not raise_error
      expect { node.replace_property(name: "bar", target: /baz/) {|value| "bob"} }.to_not raise_error
    end

    it "can take a regex property name" do
      node.replace_property(name: /.+/, target: /.+/, replacement: "FOOFOO")
      node.properties.values.each {|value| value.should == "FOOFOO" }
    end

    it "only replaces property values when the name matches" do
      node.replace_property(name: /^bar.*/, target: /.+/, replacement: "FOOFOO")
      node["bar"].should == "FOOFOO"
      node["barbell"].should == "FOOFOO"
      node["another"].should_not == "FOOFOO"
    end

    context "when given a block" do
      it "yields the property value to the block and sets the property with the return of the block" do
        node.replace_property(name: "bar", target: /.+/) {|value| value.upcase }
        node["bar"].should == "BAZ"
      end

      it "ignores replacement value" do
        node.replace_property(name: "bar", target: /.+/, replacement: "replacement value") {|value| value.upcase }
        node["bar"].should == "BAZ"
      end
    end

    it "returns modified nodes" do
      node.replace_property(name: "bar", target: /.+/, replacement: "whatever").should have(1).item
      node.replace_property(name: "asdf", target: /.+/, replacement: "whatever").should be_empty
    end

    it "does not save changes to JCR" do
      node.replace_property(name: "bar", target: /.+/, replacement: "BAZ")
      node["bar"].should == "BAZ"
      node.reload
      node["bar"].should_not == "BAZ"
    end
  end

  describe "#descendants" do
    before do
      SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(path: "/content/foo"))
      SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(path: "/content/foo/bar"))
      SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(path: "/content/foo/bar/baz"))
      SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(path: "/content/foo/bar/baz/qux"))
      SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(path: "/content/foo/baz"))
      SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(path: "/content/foo/baz/qux"))
    end

    it "returns all nodes beneath this one" do
      SafetyPin::Node.find("/content/foo").descendants.should have(5).items
    end
  end

  describe "#remove_attribute" do
    let(:node) do
      blueprint = SafetyPin::NodeBlueprint.new(:path => "/content/foo", properties: {"foo" => "bar"})
      SafetyPin::Node.create(blueprint)
    end

    it "deletes an attribute by name" do
      node.properties.keys.should include("foo")
      node.remove_attribute("foo")
      node.save
      node.refresh
      node.properties.keys.should_not include("foo")
    end
  end
end