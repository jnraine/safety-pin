$:<<File.join(File.dirname(__FILE__), '/../lib')

require 'safety_pin'

RSpec.configure do |config|
  def safe_destroy(path)
    if SafetyPin::JCR.logged_in?
      node = SafetyPin::Node.find(path)
      unless node.nil?
        node.reload if node.changed?
        node.destroy
      end
    end
  end
  
  def destroy_test_nodes
    safe_destroy("/content/foo")
    safe_destroy("/content/bar")
  end

  config.before(:all) do
    SafetyPin::JCR.dev_login
  end

  config.before do
    SafetyPin::JCR.session.refresh(false) if SafetyPin::JCR.logged_in?
  end
  
  config.after(:all) do
    SafetyPin::JCR.logout
  end
  
  config.after do
    destroy_test_nodes
  end

  config.before do
    destroy_test_nodes
  end
end