class JCR
  class Node
    def self.find(path)
      raise ArgumentError unless path.to_s.start_with?("/")
      Node.new(session.get_node(path.to_s))
    rescue javax.jcr.PathNotFoundException
      nil
    end
    
    def self.session
      JCR.session
    end
    
    attr_reader :j_node
    
    def initialize(j_node)
      @j_node = j_node
    end
    
    def path
      @path ||= j_node.path
    end
    
    def children
      child_nodes = []
      j_node.get_nodes.each do |child_j_node|
        child_nodes << Node.new(child_j_node)
      end
      child_nodes
    end
    
    def child(relative_path)
      child_j_node = j_node.get_node(relative_path)
      Node.new(child_j_node)
    rescue javax.jcr.PathNotFoundException
      nil
    end
    
    def name
      @name ||= j_node.name
    end
  end
end