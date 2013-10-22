require 'spec_helper.rb'

describe SafetyPin::JCR do
  before(:all) do
    SafetyPin::JCR.logout
  end
  
  after(:all) do
    SafetyPin::JCR.dev_login
  end
  
  it "should login to a remote JCR" do
    SafetyPin::JCR.login(:hostname => "http://localhost:4502", :username => ENV["JCR_USERNAME"], :password => ENV["JCR_PASSWORD"])
    SafetyPin::JCR.session.should be_a(Java::JavaxJcr::Session)
    SafetyPin::JCR.should be_logged_in
    SafetyPin::JCR.logout
  end
  
  it "should logout of a remote SafetyPin::JCR" do
    SafetyPin::JCR.login(:hostname => "http://localhost:4502", :username => ENV["JCR_USERNAME"], :password => ENV["JCR_PASSWORD"])
    SafetyPin::JCR.logout
    SafetyPin::JCR.should be_logged_out
  end
  
  context ".parse_hostname" do
    it "add /crx/server as the path when none is present" do
      hostname = SafetyPin::JCR.parse_hostname("http://localhost:4502")
      hostname.end_with?("/crx/server").should be_true
    end

    it "doesn't mess with the path when one is present" do
      hostname = SafetyPin::JCR.parse_hostname("http://localhost:8080/server") # like Jackrabbit
      hostname.should == "http://localhost:8080/server"
    end
  end
end