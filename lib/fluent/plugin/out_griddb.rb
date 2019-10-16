require "fluent/plugin/output"
require_relative 'griddb_auth'
require_relative 'griddb_data'
require "net/http"
require "uri"
require "yajl"
require "date"

module Fluent
  module Plugin
    class GriddbOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("griddb", self)
	  helpers :compat_parameters

      include Fluent::GridDBAuthParams
      include Fluent::GridDBAuth
	  include Fluent::GridDBData
      
      DEFAULT_BUFFER_TYPE = "memory"
      DEFAULT_FORMATTER = "json"
    
      def initialize
        super
      end
     
      config_section :buffer do
        config_set_default :@type, DEFAULT_BUFFER_TYPE
        config_set_default :chunk_keys, ['tag']
      end

      config_section :format do
        config_set_default :@type, DEFAULT_FORMATTER
      end
    
      def configure(conf)
        compat_parameters_convert(conf, :buffer, :formatter)
        super
		
		if @host.nil? || @host.empty?
			raise Fluent::ConfigError, "Host must be not null or empty"
		end
		
		if @cluster.nil? || @cluster.empty?
			raise Fluent::ConfigError, "Cluster must be not null or empty"
		end
		
		if @database.nil? || @database.empty?
			raise Fluent::ConfigError, "Database must be not null or empty"
		end
		
		if @container.nil? || @container.empty?
			raise Fluent::ConfigError, "Container must be not null or empty"
		end
		
		if @username.nil? || @username.empty?
			raise Fluent::ConfigError, "Username must be not null or empty"
		end
		
		if @password.nil? || @password.empty?
			raise Fluent::ConfigError, "Password must be not null or empty"
		end
	
		raise Fluent::ConfigError, "'tag' in chunk_keys is required." if !@chunk_key_tag && @buffered	
		
        if @formatter_config = conf.elements('format').first
          log.warn "griddb out plugin is not support format section"
        end
      end

      def start
        super
      end
    
      def shutdown
        super
      end
    
      def prefer_buffered_processing
        @buffered
      end

	  # Format data is auto supported by Fluentd
      def format(tag, time, record)
		[time, record].to_msgpack
      end
    
      def formatted_to_msgpack_binary?
        true
      end
    
      def multi_workers_ready?
        true
      end

	  # Put record to server
	  def handle_record(tag, time, record)
        req, uri = create_request(record)
        send_request(req, uri)
      end
	  
	  # Overwrite when Not use buffer
      def process(tag, es)
        es.each do |time, record|		 
		  arrays_2 = convert(record)
          handle_record(tag, time, arrays_2)
        end
      end
    
	  # Overwrite when use buffer
      def write(chunk)
        tag = chunk.metadata.tag		
        $real_container = extract_placeholders(@container, chunk)
		arrays_2 = chunk_convert(chunk)
		handle_record(tag, DateTime.now, arrays_2)
      end
     
    end
  end
end
