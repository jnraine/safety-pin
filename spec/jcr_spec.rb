require 'spec_helper.rb'

describe SafetyPin::JCR do
  it "should login to a remote SafetyPin::JCR" do
    SafetyPin::JCR.login(:hostname => "http://localhost:4502", :username => "admin", :password => "admin")
    SafetyPin::JCR.session.should be_a(Java::JavaxJcr::Session)
    SafetyPin::JCR.should be_logged_in
    SafetyPin::JCR.logout
  end
  
  it "should logout of a remote SafetyPin::JCR" do
    SafetyPin::JCR.login(:hostname => "http://localhost:4502", :username => "admin", :password => "admin")
    SafetyPin::JCR.logout
    SafetyPin::JCR.should be_logged_out
  end
  
  context ".parse_hostname" do
    it "ensures the hostname ends with /crx/server" do
      hostname = SafetyPin::JCR.parse_hostname("http://localhost:4502")
      hostname.end_with?("/crx/server").should be_true
    end
  end
end