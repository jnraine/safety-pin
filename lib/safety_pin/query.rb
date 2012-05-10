module SafetyPin
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
      JCR.session.workspace.query_manager
    end
    
    def sql
      [select_statement, where_statement].compact.join(" ")
    end
    
    def type(type)
      @type = type
    end
    
    def where(properties)
      self.where_conditions = where_conditions + properties.map {|name, value| WhereCondition.new(name, value) }
    end
    
    def within(path)
      @within ||= []
      if path.is_a? String
        @within << path
      elsif path.is_a? Array
        @within += path
      end
    end
    
    def where_conditions
      @where_conditions ||= []
    end
    
    def where_conditions=(where_conditions)
      @where_conditions = where_conditions
    end
    
    private
    def select_statement
      type = @type || "nt:base"
      "SELECT * FROM [#{type}]"
    end
    
    def where_statement
      "WHERE #{where_sql.join(" AND ")}" unless where_conditions.empty? and within_path_conditions.empty?
    end
    
    def where_sql
      (where_conditions + within_path_conditions).map(&:sql_fragment)
    end
    
    def within_path_conditions
      unless @within.nil?
        @within.map {|path| WhereCondition.new("jcr:path", "#{path}%", "LIKE") }
      else 
        []
      end
    end
  end
  
  class InvalidQuery < Exception; end
end