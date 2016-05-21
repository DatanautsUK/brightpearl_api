module BrightpearlApi
  class ResourceSearcher
    INITIAL_FIRST_RESULT = 1
    PAGE_SIZE = 500

    def initialize(service, resource, call_fn, options = nil)
      @service = service
      @resource = resource
      @call_fn = call_fn
      @options = options || {}
      @next_first_result = INITIAL_FIRST_RESULT
      @total_results_returned = 0
      @results_available = nil
      @last_page = nil
      @last_page_yielded = true
    end

    def results
      get_length = -> { length }
      Enumerator.new(get_length) do |y|
        until exhausted?
          result_hashes(next_page).each { |result| y.yield(result) }
          self.last_page_yielded = true
        end
      end
    end

    protected

    attr_accessor :options, :resource, :service, :last_page, :last_page_yielded, :next_first_result,
                  :results_available, :total_results_returned

    def call(*args)
      @call_fn.call(*args)
    end

    def exhausted?
      started? && last_page_yielded &&
        total_results_returned >= results_available
    end

    def length
      next_page unless results_available
      results_available
    end

    def next_page
      return last_page unless last_page_yielded
      params = options.merge(pageSize: PAGE_SIZE, firstResult: next_first_result)
      response = call(:get, "/#{service}-service/#{resource}-search?#{params.to_query}")
      self.total_results_returned += response['metaData']['resultsReturned']
      self.results_available = response['metaData']['resultsAvailable']
      self.next_first_result = total_results_returned + 1
      self.last_page_yielded = false
      self.last_page = response
    end

    def started?
      !last_page.nil?
    end

    def result_hashes(response)
      properties = response['metaData']['columns'].map { |x| x['name'] }
      response['results'].map do |result|
        hash = {}
        properties.each_with_index do |item, index|
          hash[item] = result[index]
        end
        hash
      end
    end
  end
end
