require 'spec_helper.rb'

describe JCR do
  it "should login to a remote JCR" do
    JCR.login(:hostname => "http://localhost:4502", :username => "admin", :password => "admin")
    JCR.session.should be_a(Java::JavaxJcr::Session)
    JCR.should be_logged_in
    JCR.logout
  end
  
  it "should logout of a remote JCR" do
    JCR.login(:hostname => "http://localhost:4502", :username => "admin", :password => "admin")
    JCR.logout
    JCR.should be_logged_out
  end
  
  context ".parse_hostname" do
    it "ensures the hostname ends with /crx/server" do
      hostname = JCR.parse_hostname("http://localhost:4502")
      hostname.end_with?("/crx/server").should be_true
    end
  end
end