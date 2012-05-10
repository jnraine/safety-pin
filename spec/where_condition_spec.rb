require 'spec_helper'

describe SafetyPin::Query::WhereCondition do
  it "should be instantiated with a name, value, and comparator" do
    where_condition = SafetyPin::Query::WhereCondition.new("foo", "bar", "LIKE")
    where_condition.should_not be_nil
  end
  
  it "should generate a SQL WHERE string fragment" do
    where_condition = SafetyPin::Query::WhereCondition.new("foo", "bar", "LIKE")
    where_condition.sql_fragment.should eql("[foo] LIKE 'bar'")
  end
  
  it "should be equal based on its main attributes" do
    condition1 = SafetyPin::Query::WhereCondition.new("foo", "bar", "LIKE")
    condition2 = SafetyPin::Query::WhereCondition.new("foo", "bar", "LIKE")
    condition1.should == condition2
    condition1.should eql(condition2)
  end
end