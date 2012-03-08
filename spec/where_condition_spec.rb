require 'spec_helper'

describe JCR::Query::WhereCondition do
  it "should be instantiated with a name, value, and comparator" do
    where_condition = JCR::Query::WhereCondition.new("foo", "bar", "LIKE")
    where_condition.should_not be_nil
  end
  
  it "should generate a SQL WHERE string fragment" do
    where_condition = JCR::Query::WhereCondition.new("foo", "bar", "LIKE")
    where_condition.sql_fragment.should eql("[foo] LIKE 'bar'")
  end
  
  it "should be equal based on its main attributes" do
    condition1 = JCR::Query::WhereCondition.new("foo", "bar", "LIKE")
    condition2 = JCR::Query::WhereCondition.new("foo", "bar", "LIKE")
    condition1.should == condition2
    condition1.should eql(condition2)
  end
end