require 'spec_helper'

describe SafetyPin::QueryBuilder do
  describe "#execute" do
    let(:node_path) { Pathname("/tmp/unique-node-name-#{Time.now.to_i}") }
    let(:node) { SafetyPin::Node.find(node_path) }

    before do
      SafetyPin::Node.create(SafetyPin::NodeBlueprint.new(path: node_path))
    end

    after do
      node.destroy if node
    end

    it "returns nodes for a query hash" do
      nodes = SafetyPin::QueryBuilder.execute(path: node_path.dirname, nodename: node_path.basename)
      nodes.length.should == 1
      nodes.first.path.should == node_path.to_s
    end
  end
end