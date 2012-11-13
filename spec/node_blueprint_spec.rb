require 'spec_helper'

describe SafetyPin::NodeBlueprint do
  let(:node_blueprint) { SafetyPin::NodeBlueprint.new(:path => "/content/foo/bar", :primary_type => "nt:folder", :properties => {"foo" => "bar"}) }

  describe "#primary_type" do
    it "has a primary type" do
      node_blueprint.primary_type.should == "nt:folder"
    end

    it "has a default primary type" do
      SafetyPin::NodeBlueprint.new(:path => "/something").primary_type.should == "nt:unstructured"
    end
  end

  describe "#properties" do
    it "has properties" do
      node_blueprint.properties.should == {"foo" => "bar"}
    end

    it "defaults to an empty hash" do
      SafetyPin::NodeBlueprint.new(:path => "/something").properties.should == {}
    end
  end

  describe "#path" do
    it "requires a path" do
      expect { SafetyPin::NodeBlueprint.new({}).path }.to raise_error(SafetyPin::NodeBlueprintError)
    end

    it "has a path" do
      node_blueprint.path.should == "/content/foo/bar"
    end
  end
end