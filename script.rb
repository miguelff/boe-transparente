# encoding: utf-8
require 'faraday'
require 'erb'
require 'digest/sha1'

class Connection

  BASE = 'http://www.boe.es'

  def self.instance
    conn = Faraday.new(url: BASE) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end
  end
end

class Scraper

  attr_reader :text, :http

  def initialize(text, options = {})
    @text = text
    @http = options[:http] || Connection.instance
  end

  def sections
    sections = {}
    current_section = nil

    text.split("\n").each do |line|
      if line.strip.start_with?("#")
        current_section = line.gsub("#", '').strip
        sections[current_section] ||= Set.new
      elsif line.start_with?('Disallow:')
        line = line.gsub('Disallow:', '').strip
        link = LinkBuilder.new(line, self).build
        sections[current_section] << link if link
      else
        next
      end
    end

    sections
  end

  private

  class LinkBuilder

    def initialize(url, scraper)
      @url = url
      @scraper = scraper
    end

    def build
      Link.new.tap do |link|
        link.href = href
        link.text = href
        link.classes = classes
        link.digest = digest
        link.priority = priority
      end if valid?
    end

    private

    attr_reader :url, :scraper

    class Link
      attr_accessor :href, :classes, :text, :digest, :priority

      # To avoid presenting duplicated links pointing to the same contents
      def hash
        digest.hash
      end

      def eql?(other)
        self.digest == other.digest
      end

      def <=>(other)
        other.priority - self.priority
      end
    end

    def valid?
      @valid ||= (!regex? && relative? && !search? && !index? && points_to_content?)
    end

    def regex?
      url.include?('*') || url.include?('$')
    end

    def relative?
      url.include?('/')
    end

    def search?
      url.include?("/buscar")
    end

    def index?
      url.include?('index.php')
    end

    def points_to_content?
      res.status == 200 && !(textual? && shows_error?)
    end

    def digest
      Digest::SHA1.hexdigest body
    end

    def textual?
      %w(html text xml).any? { |mime| headers["content-type"].include?(mime) }
    end

    # Naïve implementation
    def shows_error?
      body.include?("que solicita no existe") || body.include?("Error de parámetros")
    end

    def classes
      @classes ||= begin
        [].tap do |c|
          c << :pdf if url.include?("pdf")
          c << :txt if url.include?("txt")
          c << :xml if url.include?("xml")
          c << :index if url.end_with?('/')
          c << :unknown if c.empty?
        end
      end
    end

    # unkown type links are the ones with least priority, index pages the ones with most
    def priority
      classes.reduce(0) do |priority, klass|
        priority += (2 ** ([:unknown, :text, :xml, :pdf, :index].index(klass) || 0))
      end
    end

    def href
      @href ||= "#{Connection::BASE}#{url}"
    end

    def body
      @body ||= res.body.force_encoding('UTF-8')
    end

    def headers
      @headers ||= res.headers
    end

    def res
      @res ||= http.get url
    end

    def http
      scraper.http
    end
  end
end

class Builder

  attr_reader :sections

  def initialize(sections)
    @sections = sections
  end

  def html
    ERB.new(template).result(binding)
  end

  def template
    File.read('template.html.erb')
  end
end

if $0 == __FILE__
  conn = Connection.instance

  contents = conn.get("/robots.txt").body
  hash = Digest::SHA1.hexdigest contents
  file_name = "#{hash}.html"

  if File.exist?(file_name)
    puts "#{file_name} already exists"
  else
    scraper = Scraper.new(contents, http: conn)
    builder = Builder.new(scraper.sections)
    File.open(file_name, 'w') do |f|
      f.write(builder.html)
    end
    `ln -sf #{file_name} index.html`
  end

  `open index.html` rescue nil
end