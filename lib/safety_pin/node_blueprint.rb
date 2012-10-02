module SafetyPin
  class NodeBlueprint
    attr_accessor :path, :primary_type, :properties

    def initialize(opts)
      raise NodeBlueprintError.new("No path specified") unless opts[:path]
      @path = opts[:path]
      @primary_type = opts[:primary_type] || "nt:unstructured"
      @properties = opts[:properties] || {}
    end

    def node_blueprint?
      true
    end
  end

  class NodeBlueprintError < Exception; end
end