module Error
  class MyError < StandardError
    attr_reader :status, :error, :code, :message

    def initialize(_error = nil, _code = nil, _status = nil, _message = nil)
      @error = _error || 422
      @status = _status || :unprocessable_entity
      @code = _code || 3
      @message = _message || 'Something went wrong'
    end

    def fetch_json
      Helpers::Render.json(error)
    end
  end
end