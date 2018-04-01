require 'net/http'
require 'json'

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
  site.data['pdfs'] = result['response']['docs']
end
