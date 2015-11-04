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

    def create_resource(service, resource)
      body = {}
      yield(body)
      call(:post, "/#{service}-service/#{resource}/", body)
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
      call(:put, "/#{service}-service/#{resource}/#{resource_id.to_i}", body)
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

    def search_resource(service, resource)
      body = {}
      yield(body)
      body[:pageSize] = 500
      body[:firstResult] = 1
      result_hash = []
      results_returned = 0
      results_available = 1
      while results_returned < results_available
        response = call(:get, "/#{service}-service/#{resource}-search?#{body.to_query}")
        results_returned += response['metaData']['resultsReturned']
        results_available = response['metaData']['resultsAvailable']
        body[:firstResult] = results_returned + 1
        properties = response['metaData']['columns'].map { |x| x['name'] }
        response['results'].each do |result|
          hash = {}
          properties.each_with_index do |item, index|
            hash[item] = result[index]
          end
          result_hash << hash
        end
      end
      result_hash
    end

    def multi_message
      body = {}
      yield(body)
      call(:post, "/multi-message", body)
    end
  end
end
