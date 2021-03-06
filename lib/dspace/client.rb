module Dspace
  class Client
    DSPACE_API = 'https://demo.dspace.org'

    attr_accessor :access_token

    def initialize(options = {})
      @access_token = options.with_indifferent_access[:access_token]
      @dspace_api = options.with_indifferent_access[:dspace_api]
      @logger = options.with_indifferent_access[:logger]
      @adapter = options.with_indifferent_access[:adapter]
      @timeout = options.with_indifferent_access[:timeout]
      @open_timeout = options.with_indifferent_access[:open_timeout]
    end

    def connection
      @conn ||= Faraday.new(connection_options) do |req|
        req.request :multipart
        req.request :url_encoded
        req.use(Faraday::Response::Logger, @logger) unless @logger.blank?
        req.options.open_timeout = @open_timeout unless @open_timeout.blank?
        req.options.timeout = @timeout unless @timeout.blank?
        if @adapter == :net_http_persistent
          req.adapter Dspace::Adapter::NetHttpPersistent
        else
          req.adapter @adapter unless @adapter.blank?
        end
      end
      @conn
    end

    def close_connection
      @conn.close unless @conn.nil?
    end

    def self.resources
      {
          bitstreams: ::Dspace::Resources::BitstreamResource,
          items: ::Dspace::Resources::ItemResource,
          collections: ::Dspace::Resources::CollectionResource,
          communities: ::Dspace::Resources::CommunityResource,
          status: ::Dspace::Resources::StatusResource,
          authentication: ::Dspace::Resources::AuthenticationResource,
          schema_registry: ::Dspace::Resources::SchemaRegistryResource,
          hierarchy: ::Dspace::Resources::HierarchyResource,
          report: ::Dspace::Resources::ReportResource
      }
    end

    def method_missing(name, *args, &block)
      resource(name) || super
    end

    def resources
      @resources ||= {}
    end

    def is_running?
      resource(:status).test
    end

    def status
      resource(:status).status
    end

    def login(email, password)
      @access_token = resource(:authentication).login(email: email, password: password)
      connection.headers['Cookie'] = @access_token
      @access_token
    end

    def logout
      response = resource(:authentication).logout
      connection.headers['Cookie'] = ""
      @access_token = nil
      response
    end

    private

    def resource(name)
      if self.class.resources.keys.include?(name)
        resources[name] = self.class.resources[name].new(connection: connection)
      end
    end

    def connection_options
      {
        url: @dspace_api || DSPACE_API,
        ssl: {
          verify: false
        },
        headers: {
          content_type: 'application/json',
          accept: 'application/json',
          user_agent: "dspace-rest-client #{Dspace::VERSION}",
          'Cookie' => @access_token.to_s
        }
      }
    end
  end
end
