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
      json = Helpers::Render.json(_error)
      render json: json, status: _status
    end
  end
end