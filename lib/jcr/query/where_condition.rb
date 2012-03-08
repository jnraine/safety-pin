class JCR
  class Query
    class WhereCondition
      attr_reader :name, :value, :comparator
      
      def initialize(name, value, comparator = "=")
        @name = name
        @value = value
        @comparator = comparator
      end
    
      def sql_fragment
        "[#{name}] #{comparator} '#{value}'"
      end
      
      def ==(object)
        self.name == object.name and self.value == object.value and self.comparator == object.comparator
      end
      
      def eql?(object)
        self == object
      end
    end
  end
end