module Error
  class SubscriberNotFoundError < StandardError
    attr_reader :status, :code, :error, :message

    def initialize(_error = nil, _code = nil, _status = nil, _message = nil)
      @error = _error || 3
      @code = _code || 3
      @status = _status || :unprocessable_entity
      @message = _message || 'SUBSCRIBER_NOT_FOUND'
    end

    def fetch_json
      Helpers::Render.json(error)
    end
  end
end