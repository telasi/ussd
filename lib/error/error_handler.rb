module Error
  module ErrorHandler
    def self.included(clazz)
      clazz.class_eval do
        rescue_from StandardError do |e|
          respond(e, 404)
        end
      end
    end

    private

    def respond(_error, _status)
      # json = Helpers::Render.json(_error)
      json = {
          error: {
            message: _error.message,
            code:    _error.code || 3
          }
        }.as_json
      render json: json, status: _status
    end
  end
end