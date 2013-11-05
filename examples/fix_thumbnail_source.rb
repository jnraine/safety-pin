require_relative 'lib/safety-pin'
include SafetyPin
require 'logger'

JCR.login(hostname: "http://localhost:4502", username: "admin", password: "admin")

$log = Logger.new(STDOUT)

def filter_out_clf1(nodes)
  nodes.delete_if do |n| 
    pageContent = n.parents.find do |parent| 
      parent.primary_type == "cq:PageContent" or parent.name == "jcr:content"
    end

    if pageContent
      delete_me = !pageContent.properties["sling:resourceType"].start_with?("clf")
      if delete_me
        $log.info "#{n.path} is CLF 1 (#{pageContent.properties["sling:resourceType"]})"
        delete_me
      else
        $log.info "#{n.path} is CLF 2 (#{pageContent.properties["sling:resourceType"]})"
        delete_me
      end
    else
      $log.info "#{n.path} has no page content parent"
      true
    end
  end

  nodes
end

def set_thumbnail_source(nodes, value)
  property_name = "thumbnailSource"
  nodes.each_with_index do |node, i|
    if node.properties[property_name] != "thumbnailField" or node.properties[property_name] != "imageTab" # these are the only two valid values, otherwise force sane default
      $log.info "Changing #{node.path} #{property_name.inspect} to #{value.inspect}"
      node[property_name] = value
      if i % 10 == 0
        $log.info "Saving changes..."
        node.save
      end
    else
      $log.info "#{node.path} has #{property_name.inspect} property value of #{node[property_name].inspect}. Skipping change."
    end
  end
  $log.info "Saving last changes..."
  JCR.save
end

def fix_nodes(nodes, job_name)
  $log.info "Starting to fix #{nodes.length} #{job_name}..."
  $log.info "#{nodes.length} unfiltered nodes"
  nodes = filter_out_clf1(nodes)
  $log.info "#{nodes.length} filtered CLF2 nodes"
  set_thumbnail_source(nodes, "thumbnailField")
  $log.info "Done processing #{nodes.length} for #{job_name}"
end

# Should set teaser displays thumbnail source to "thumbnailField" for new CLF pages only
teaser_nodes = QueryBuilder.execute({
  "1_property"=>"sling:resourceType",
  "1_property.value"=>"foundation/components/list",
  "2_property"=>"displayAs",
  "2_property.value"=>"teaser",
  "path"=>"/content/sfu",
  "p.limit" => -1
})
fix_nodes(teaser_nodes, "teaser lists")

# Should set headline displays thumbnail source to "thumbnailField" for new CLF pages only
headline_nodes = QueryBuilder.execute({
  "1_property"=>"sling:resourceType",
  "1_property.value"=>"foundation/components/list",
  "2_property"=>"displayAs",
  "2_property.value"=>"headline",
  "path"=>"/content/sfu",
  "p.limit" => -1
})
fix_nodes(headline_nodes, "headline lists")

# Should set news list displays thumbanil source to "thumbnailField" for new CLF pages only
news_list_nodes = QueryBuilder.execute({
  "1_property"=>"sling:resourceType",
  "1_property.value"=>"foundation/components/list",
  "2_property"=>"displayAs",
  "2_property.value"=>"newsList",
  "path"=>"/content/sfu",
  "p.limit" => -1
})
fix_nodes(news_list_nodes, "news lists")

# Should set news list displays thumbanil source to "thumbnailField" for new CLF pages only
news_feed_nodes = QueryBuilder.execute({
  "1_property"=>"sling:resourceType",
  "1_property.value"=>"foundation/components/list",
  "2_property"=>"displayAs",
  "2_property.value"=>"newsFeed",
  "path"=>"/content/sfu",
  "p.limit" => -1
})
fix_nodes(news_feed_nodes, "news feed lists")
