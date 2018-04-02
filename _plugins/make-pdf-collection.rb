require 'net/http'
require 'json'
require 'pry'

Jekyll::Hooks.register :site, :post_read do |site|
  url = site.config['solr']
  resp = Net::HTTP.get_response(URI.parse(url))
  data = resp.body

  # we convert the returned JSON data to native Ruby
  # data structure - a hash
  result = JSON.parse(data)

  # if the hash has 'Error' as a key, we raise an error
  if result.has_key? 'Error'
    raise "web service error"
  end
  docs = result['response']['docs']
  site.data['docs'] = docs
  docs.each do |doc|
    site.config['facets'].keys.each do |collection|
      site.data[collection] = {} unless site.data[collection]
      facet = site.config['facets'][collection]
      terms = {}
      field = facet['field']
      if doc[field]
        doc[field].each do |term|
          site.data[collection][term] = [] unless site.data[collection][term]
          site.data[collection][term] << doc
        end
      end
    end
    site.config['facets'].keys.each do |collection|
      site.data[collection + '_keys'] = site.data[collection].keys.sort
    end
  end
end
