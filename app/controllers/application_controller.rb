class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :save_request
  after_action :save_response

  include Error::ErrorHandler

  private 

  def save_request
  	@jsonBody = JSON.parse(request.body.read)
  rescue
  	raise 'Wrong format'
  	# Log.new(uuid: request.uuid, path: request.path, body: request.body.read[0...200], request_time: Time.now).save
  end

  def save_response
  	# log = Log.find(response.request.uuid)
  	# log.update_attributes(response: response.body, status: response.status, response_time: Time.now) if log.present?
  end
end
