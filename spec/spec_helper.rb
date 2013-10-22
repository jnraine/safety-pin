$:<<File.join(File.dirname(__FILE__), '/../lib')

require 'safety_pin'

RSpec.configure do |config|
  def destroy_foo
    if SafetyPin::JCR.logged_in?
      node = SafetyPin::Node.find("/content/foo")
      unless node.nil?
        node.reload if node.changed?
        node.destroy
      end
    end
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
    destroy_foo
  end

  config.before do
    destroy_foo
  end
end