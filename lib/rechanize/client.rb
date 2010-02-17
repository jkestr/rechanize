require 'uri'
require 'logger'
require 'mechanize'
require 'rechanize/string'
require 'rechanize/errors'
require 'rechanize/xml'

module Rechanize
  class Client

    METHODS = ["Search", "GetObject", "Login", "GetMetadata"]
    attr_reader :paths

    # Set everything up for delicious fun
    def initialize(login_url, options={})
      opts = options.reverse_merge({:logger => STDOUT})

      @paths = {}
      @login_url = URI.parse(login_url)
      @logger = Logger.new(opts[:logger]) if opts[:logger]

      return
    end
  
    def agent
      if @agent.nil?
        @agent = WWW::Mechanize.new
        @agent.auth(@login_url.user, @login_url.password)
      end

      @agent
    end

    def port
      @login_url.port
    end

    def host
      @login_url.host
    end

    def user
      @login_url.user
    end

    def scheme
      @login_url.scheme
    end

    def login_path
      @login_url.path
    end

    def log(type, msg)
      if @logger
        @logger.send(type, msg)
      end
    end
  
    def inspect
      "<RETS::#{host} #{user}>"
    end

    # Attempt to authenticate ourselves
    def authenticate()
      path = build_uri(login_path)
      page = agent.get(path)
      data = Xml.parse(page.content)
      log(:info, "Authentication Response: #{data}")
      set_paths(parse_paths(data))
      return authenticated?
    end

    # Attempt to authenticate this connection.
    # Raises AuthenticationError if unable to authenticate.
    def authenticate!
      raise Rechanize::AuthenticationError if !authenticate()
      return authenticated?
    end

    # Returns true if it appears this connection is authorized
    def authenticated?
      return !@paths.empty?
    end

    # Fetch metadata
    def metadata(type = "OBJECT")
      path = path("GetMetadata")
      path << "Type=METADATA-#{type}&Format=COMPACT&Id=0"    
      page = agent.get(path)
      page.content
    end

    # Write the metadata response to a file
    def metadata!(path, type = "OBJECT")
      File.open(File.expand_path(path), "w") do |f|
        f << metadata(type).read
      end
    end

    # Request a query from the RETS service.
    # Returns each item to the block provided.
    # Data requests yield |data|
    # Image requests yield |index, headers, data|
    def get(query, options = {}, &block)
      path = build_path(query, options)
      log(:debug, "GET " << path)
      page = @agent.get(path)
      parse(page, options, &block)
    end

    # Get the full URI for a method.
    def path(method)
      paths[method]
    end

    # Parse the result from RETS server.
    def parse(page, options, &block)
      case 
      when page.header["content-type"] =~ /text\/xml/
        parse_xml(page, &block)
      when page.header["content-type"] =~ /multipart\/parallel/
        parse_multipart(page, &block)
      when page.header["content-type"] =~ /image\//
        yield 0, page.header, page.content  
      else # XML errors come back as plain/text
        begin
          parse_xml(page, &block)
        rescue
          raise UnsupportedContentType.new(page.header['content-type'])
        end
      end
    end

    # Build the path for a query request
    def build_path(query, options, type = /Type=HrPhoto/)
      method = (query =~ type ? "GetObject" : "Search")
      result = path(method).dup
      raise UnsupportedRequest.new("Server does not accept #{type}")
  
      if method == "Search"
        options["Format"] = "COMPACT"
        options["QueryType"] = "DMQL2"
      
        if options.key?(:limit) 
          options["Limit"] = options.delete(:limit).to_s
        end
      end
    
      result << "?" << query

      if !options.empty?
        result << "&" << options.map { |k,v| "#{k}=#{v}" }.join("&")
      end

      return result
    end

    # Set the known action/method URIs for this connection
    # paths:: "Action" => "/some/path" hash of method paths
    # Login will always be present when finished.
    def set_paths(new_paths = {})
      paths.clear
      new_paths.each_pair { |key, value|
        paths[key] = build_uri(value)
      }
      paths.keys
    end
  
    # Build a URI from a path 
    def build_uri(path)
      raise InvalidPathError if !(path =~ /^\/.*$/)
      "#{scheme}://#{host}:#{port}#{path}"
    end

    # Not the same kind of parser as the rest, but I figured it would be less confusing
    # when searching to find this in a totally different place.
    # Name recomendations?
    def parse_paths(data, key = "RETS-RESPONSE")
      sets = data[key].multisplit("\n", "=")
      sets = sets.select { |k, v| method_known?(k) }
      sets.to_hash
    end

    def method_known?(method)
      known_methods.include?(method)
    end

    def known_methods
      METHODS
    end

    # Parse a RETS xml pack
    # There is no reason to raise an exception if no results are found.
    def parse_xml(page, &block)
      data = Xml.parse(page.content)

      case data["ReplyCode"]
      when "0"
        result = block_given? ? nil: []
        parse_xml_compact(data) { |item|
          result.nil? ? (yield item) : (result << item)
        }
      when "20201"
        log(:debug, "XML contains no results to parse")
      else
        log(:warn, "Unknown reply code #{data['ReplyCode']} #{data['ReplyText']}")
        raise RequestError.new("[RETS #{data['ReplyCode']}] #{data['ReplyText']}")
      end

      return result
    end
  
    # Parse a RETS compact XML item into something digestable
    # <COLUMNS>\tKEY\tKEY2</COLUMNS>
    # <DATA>\tVALUE\tVALUE2</DATA>
    # #=> {'KEY' => 'VALUE', 'KEY2' => 'VALUE2'}
    def parse_xml_compact(data, key = "RETS_RESPONSE", &block)
      del = data["DELIMITER"]["value"].to_i.chr
      fields = data["COLUMNS"].split(del)

      data["DATA"].each do |row|
        values = row.split(del)
        yield fields.zip_hash(values)
      end
  
      return
    end

    # Parse multipart content into invidiual pieces
    # Yields |index, header, data| for each item
    def parse_multipart(data, &block)
      case data.header["content-type"]
      when /multipart\/parallel/
        parse_parallel(data, &block)
      else
        raise MultipartError.new("Unknown content type #{data.header['content-type']}")
      end
    end

    # Parse a multipart parallel into invidiual pieces
    # Yields |index, headers, data| for each item
    def parse_parallel(data, &block)
      heads = (data.header["content-type"]).multisplit(";", "=")
      headers = heads.to_hash
      boundary = "\r\n--#{headers['boundary']}"

      parts = data.content.split(boundary)
      parts.shift # hephalumps and woozles

      parts.each_with_index do |part, index|
        (raw_header, raw_data) = part.split("\r\n\r\n")
        next unless raw_data
        header = raw_header.multisplit("\n", ":").to_hash
        yield(index, header, raw_data)
      end

      return
    end

  end
end

