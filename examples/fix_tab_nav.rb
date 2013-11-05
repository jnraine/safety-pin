require_relative "lib/safety-pin"

include SafetyPin
JCR.login(hostname: "http://localhost:4502", username: "admin", password: "admin")

@query_path = "/content/clf/students/academic-calendar-archive"

def tab_navs
  QueryBuilder.execute(
    "path" => @query_path,
    "property" => "sling:resourceType",
    "property.value" =>"sfu/components/tabnav",
    "p.limit" => "-1"
  )
end

def denest_tab_navs
  nested_tab_navs = tab_navs.delete_if {|tab_nav| tab_nav.parent.name != "tab_content" }
  puts "#{nested_tab_navs.length} nested tab navs found"
  nested_tab_navs.each_with_index do |nested_tab_nav, i|
    puts "#{i} De-nesting tab nav #{nested_tab_nav.path}"
    parsys_parent_path = nil
    parent_tab_nav = nil
    nested_tab_nav.parents.each do |parent|
      if parent.name != "tab_content" && parent["sling:resourceType"] == "foundation/components/parsys"
        parsys_parent_path = parent.path
        break
      elsif parent["sling:resourceType"] == "sfu/components/tabnav"
        parent_tab_nav = parent
      end
    end
    nested_tab_nav.move_within(parsys_parent_path, auto_rename: true)
    nested_tab_nav.order_after(parent_tab_nav.name)
  end

  JCR.session.save

  nested_tab_navs.map(&:path)
end

def move_content(tab_nav)
  main_content = tab_nav.parent
  tab_content = tab_nav.child("tab_content")
  return unless tab_content

  tab_content.children.reverse.each do |component_node|
    component_node.move_within(main_content.path, auto_rename: true)
    component_node.order_after(tab_nav)
  end
  tab_content.save
end

def convert_to_list(tab_nav)
  tab_nav["sling:resourceType"] = "foundation/components/list"
  tab_nav["displayAs"] = "horizontal"
  tab_nav.save
end

def redirect_pages_with_tabnav_references
  reference_components = QueryBuilder.execute(
    "path" => @query_path,
    "1_property" => "sling:resourceType",
    "1_property.value" => "foundation/components/reference",
    "2_property" => "path",
    "2_property.value" => "%tabnav%",
    "2_property.operation" => "like",
    "p.limit" => "-1"
  )

  puts "#{reference_components.length} redirects needed"
  reference_components.map do |reference_component|
    page_content = reference_component.parents.find {|parent| parent.primary_type == "cq:PageContent" || parent.name == "jcr:content" }
    if page_content
      page_content["redirectTarget"] = reference_component["path"].gsub(/\/jcr:content.+$/, "")
      puts "Redirecting #{page_content.parent.path} to #{page_content["redirectTarget"]}"
    else
      puts "No page content node found as parent of #{reference_component.path}"
    end
  end

  JCR.save
end

denest_tab_navs
cache_tab_navs = tab_navs
puts "#{cache_tab_navs.length} tab navs to convert"
cache_tab_navs.each_with_index do |tab_nav, i|
  puts "#{i} Converting tab nav #{tab_nav.path}"
  move_content(tab_nav)
  convert_to_list(tab_nav)
end
redirect_pages_with_tabnav_references