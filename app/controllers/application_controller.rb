class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :custom_headers
  after_filter { flash.discard if request.xhr? }

protected
  def custom_headers
    response.headers['X-Clacks-Overhead'] = 'GNU Terry Pratchett'
  end
end
