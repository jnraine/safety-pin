class JCR
  class Query
    def self.execute(query_string)
      query = query_manager.create_query(query_string, "JCR-SQL2")
      node_iter = query.execute.nodes
      nodes = []
      while node_iter.has_next
        nodes << Node.new(node_iter.next_node)
      end
      nodes
    end
    
    def self.query_manager
      @@query_manager ||= JCR.session.workspace.query_manager
    end
  end
end