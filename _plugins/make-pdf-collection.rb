require 'net/http'
require 'json'
require 'slugify'
require "addressable/template"
require 'pry'

Jekyll::Hooks.register :site, :post_read do |site|
  template = Addressable::Template.new(site.config['solr-base'] + '/select/{?query*}')
  url = template.expand({
    "query" => {
      'q' => site.config['solr-scope'],
      'version' => site.config['solr-version'],
      'start' => 0,
      'rows' => 10000000,
      'wt' => 'json',
      'fl' => site.config['solr-fields'],
      'sort' => 'date asc, date_precision desc'
    }
  }).to_s
  resp = Net::HTTP.get_response(URI.parse(url))
  data = resp.body
  result = JSON.parse(data)

  # if the hash has 'Error' as a key, we raise an error
  if result.has_key? 'Error'
    raise "web service error"
  end
  # save docs in hash keyed by id
  docs = {}
  result['response']['docs'].each {|doc| docs[doc['id']] = doc }
  site.data['docs'] = docs
end

module Jekyll
  class DocumentsPage < Page
    def initialize(site, base)
      @site = site
      @base = base
      @dir = '.'
      @name = 'documents.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'docs.html')

      self.data['title'] = 'Documents'
      self.data['docs'] = site.data['docs'].keys
    end
  end

  class FacetPage < Page
    def initialize(site, base, dir, facet, term)
      @site = site
      @base = base
      @dir = dir
      @name = term.slugify(true) + '.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'docs.html')

      template = Addressable::Template.new(site.config['solr-base'] + '/select/{?query*}')
      url = template.expand({
        "query" => {
          'q' => facet['field'] + ':"' + term + '"',
          'fq' => site.config['solr-scope'],
          'version' => site.config['solr-version'],
          'start' => 0,
          'rows' => 1000000,
          'wt' => 'json',
          'fl' => 'id',
          'sort' => 'date asc, date_precision desc'
        }
      }).to_s
      resp = Net::HTTP.get_response(URI.parse(url))
      data = resp.body
      result = JSON.parse(data)

      if result.has_key? 'Error'
        raise "web service error"
      end

      self.data['title'] = term
      docs = []
      result['response']['docs'].each {|doc| docs << doc['id'] }
      self.data['docs'] = docs
      # leave this page out of the nav header
      self.data['exclude_from_header'] = true
    end
  end

  class TOCPage < Page
    def initialize(site, base, dir, title, terms)
      @site = site
      @base = base
      @dir = dir
      @name = title.slugify(true) + '.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'toc.html')

      self.data['title'] = title
      self.data['terms'] = {}
      terms.each { |term| 
        self.data['terms'][term.keys.first] = term[term.keys.first]
      }
    end
  end

  class FacetPageGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'docs'

        # documents.html (needs to be paginated)
        site.pages << DocumentsPage.new(site, site.source)

        targetdir = site.config['facet_dir'] || 'facets'
        site.config['facets'].each_key do |facetkey|
          # here's where we fetch the term list
          facet = site.config['facets'][facetkey]
          terms = {}
          field = facet['field']
          template = Addressable::Template.new(site.config['solr-base'] + '/select/{?query*}')
          url = template.expand({
            "query" => {
              'q' => site.config['solr-scope'],
              'version' => site.config['solr-version'],
              'start' => 0,
              'rows' => 0,
              'wt' => 'json',
              'facet' => true,
              'facet.field' => field,
              'facet.sort' => 'index',
              'facet.mincount' => 1
            }
          }).to_s
          resp = Net::HTTP.get_response(URI.parse(url))
          data = resp.body
          result = JSON.parse(data)

          if result.has_key? 'Error'
            raise "web service error"
          end

          terms = []
          result['facet_counts']['facet_fields'][field].each_slice(2) do |term|
            terms << {term[0] => term[1]}
          end

          # facet menu pages
          site.pages << TOCPage.new(site, site.source, targetdir, facet['label'], terms)

          # facet term pages
          terms.each do |term|
            site.pages << FacetPage.new(site, site.source, targetdir, facet, term.keys.first)
          end
        end
      end
    end
  end
end
