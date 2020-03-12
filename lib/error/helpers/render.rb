module Error::Helpers

    class Render
      def self.json(_error)
        
        {
          error: {
          	message: _error.message,
          	code:    _error.respond_to?(:code) ? _error.code : 3
          }
        }.as_json
      end
    end

end