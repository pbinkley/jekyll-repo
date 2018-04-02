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
  site.config['facets'].keys.each do |collection|
    facet = site.config['facets'][collection]
    terms = {}
    field = facet['field']
    docs.each do |doc|
      if doc[field]
        doc[field].each do |term|
          if terms[term]
            terms[term] << doc
          else
            terms[term] = [doc]
          end
        end
      end
    end
    site.data[collection] = terms
    site.data[collection + '_keys'] = terms.keys.sort
  end
end
