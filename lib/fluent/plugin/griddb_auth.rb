#!/usr/bin/env ruby

$:.unshift File.dirname(__FILE__)

module Fluent
	module GridDBAuthParams
		def self.included(klass)
		  klass.instance_eval {
			desc "Host to GridDB Server"
			# Endpoint URL ex. http://localhost.local/api/
			config_param :host, :string
			
			desc "Cluster name"
			# Cluster name to GridDB Server
			config_param :cluster, :string
			
			desc "Database name"
			# Database name in GridDB Server
			config_param :database, :string
			
			desc "Container name"
			# Container name in database
			config_param :container, :string
		   
			desc "Username of GridDB account"
			# GridDB username account
			config_param :username, :string, :default => ''

			desc "Password of GridDB account"
			# GridDB password account
			config_param :password, :string, :default => '', :secret => true
	  
			# Switch non-buffered/buffered plugin
			config_param :buffered, :bool, :default => false
		  }
		end
	end
  
  module GridDBAuth

    # Set type for request body
    def set_body(req, record)
       req.body = Yajl.dump(record)
       req['Content-Type'] = 'application/json'
    end

    # Create new request
    def create_request(record)
      url = format_url()
      uri = URI.parse(URI.encode(url))
      req = Net::HTTP::Put.new(uri.request_uri)
	  req.basic_auth(@username, @password)
      set_body(req, record)
      return req, uri
    end

    # Send request
    def send_request(req, uri)
      res = nil
      begin      
        @last_request_time = Time.now.to_f        
        res = Net::HTTP.start(uri.host, uri.port) {|http| http.request(req) }
  
      rescue => e 
        log.warn "Net::HTTP.#{req.method.capitalize} raises exception: #{e.class}, '#{e.message}'"
        raise e if @raise_on_error
      else
         unless res and res.is_a?(Net::HTTPSuccess)
            res_summary = if res
                             "#{res.code} #{res.message} #{res.body}"
                          else
                             "res=nil"
                          end
            log.warn "failed to #{req.method} #{uri} (#{res_summary})"
         end
      end
    end
    
    # Get URL to API
    def format_url()
		if $real_container.nil? || $real_container.empty?
			@host + "/griddb/v2/" + @cluster + "/dbs/" + @database + "/containers/" + @container + "/rows"
		else
			@host + "/griddb/v2/" + @cluster + "/dbs/" + @database + "/containers/" + $real_container + "/rows"
		end        
    end

  end
end