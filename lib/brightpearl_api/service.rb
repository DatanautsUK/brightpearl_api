require 'brightpearl_api/resource_searcher'
require 'brightpearl_api/services/contact'
require 'brightpearl_api/services/order'
require 'brightpearl_api/services/product'
require 'brightpearl_api/services/warehouse'

module BrightpearlApi
  class Service
    include Contact
    include Order
    include Product
    include Warehouse

    def initialize
      raise BrightpearlException, "Configuration is invalid" unless Configuration.instance.valid?
    end

    def call(type, path, data = {})
      Client.instance.call(type, path, data)
    end

    def call_fn
      -> (*args) { call(*args) }
    end

    def parse_idset(idset)
      id_set = nil
      case idset
      when Range
        id_set = "#{idset.min.to_i}-#{idset.max.to_i}"
      when Array
        id_set = idset.map(&:to_i).join('.')
      else
        id_set = idset
      end
      id_set
    end

    def create_resource(service, resource, resource_id=nil, path=nil)
      body = {}
      yield(body)
      puts body.inspect
      if !resource_id.nil?
        call(:post, "/#{service}-service/#{resource}/#{resource_id.to_i}/#{path}", body)
      else
        call(:post, "/#{service}-service/#{resource}/#{path}", body)
      end
    end

    def get_resource(service, resource, idset = nil, includeOptional = [])
      if !idset.nil?
        id_set = parse_idset(idset)
        call(:get, "/#{service}-service/#{resource}/#{id_set}?includeOptional=#{includeOptional.join(',')}")
      else
        call(:get, "/#{service}-service/#{resource}?includeOptional=#{includeOptional.join(',')}")
      end
    end

    def update_resource(service, resource, resource_id)
      body = {}
      yield(body)
      call(:patch, "/#{service}-service/#{resource}/#{resource_id.to_i}", body)
    end

    def delete_resource(service, resource, resource_id)
      call(:delete, "/#{service}-service/#{resource}/#{resource_id.to_i}")
    end

    # returns a set of URIs you'd need to call if you would like to retrieve a large set of resources
    def get_resource_range(service, resource, idset = nil)
      if !idset.nil?
        id_set = parse_idset(idset)
        call(:options, "/#{service}-service/#{resource}/#{id_set}")
      else
        call(:options, "/#{service}-service/#{resource}")
      end
    end

    def search_resource(service, resource, options = nil)
      options ||= {}
      yield(options) if block_given?
      ResourceSearcher.new(service, resource, call_fn, options).results
    end

    def multi_message
      body = {}
      yield(body)
      call(:post, "/multi-message", body)
    end
  end
end
