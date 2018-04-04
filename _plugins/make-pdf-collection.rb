require 'net/http'
require 'json'
require 'slugify'
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

module Jekyll
  class FacetPage < Page
    def initialize(site, base, dir, key, docs)
      @site = site
      @base = base
      @dir = dir
      @name = key.slugify(true) + '.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'docs.html')

      self.data['title'] = key
      self.data['docs'] = docs
      self.data['exclude_from_header'] = true
    end
  end

  class TOCPage < Page
    def initialize(site, base, dir, key)
      @site = site
      @base = base
      @dir = dir
      @name = key.slugify(true) + '.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'toc.html')

      self.data['title'] = site.config['facets'][key]['label']
      self.data['collection'] = key
    end
  end

  class FacetPageGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'docs'
        dir = site.config['facet_dir'] || 'facets'
        site.config['facets'].each_key do |facet|
          site.pages << TOCPage.new(site, site.source, dir, facet)
          site.data[facet].keys.each do |key|
            site.pages << FacetPage.new(site, site.source, dir, key, site.data[facet][key])
          end
        end
      end
    end
  end
end
