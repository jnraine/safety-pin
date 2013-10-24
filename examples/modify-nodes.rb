# This example illustrates how to find all components of a particular type and
# modify them in some way.

require 'safety-pin'
include SafetyPin

# Login to a JCR
JCR.login(hostname: "http://localhost:4502", username: "admin", password: "admin")

# Find all text components
component_nodes = QueryBuilder.execute(
  "path" => "/content",
  "property" => "sling:resourceType",
  "property.value" =>"foundation/components/text",
  "p.limit" => "10"
)

# Modify them
component_nodes.each do |component_node|
  puts "Modifying #{component_node.path}"
  # Modify existing property
  component_node["text"] += "safety pin was here"
  # Add new property
  component_node["touched-by-safety-pin"] = true
  # Save all changes
  component_node.save
end