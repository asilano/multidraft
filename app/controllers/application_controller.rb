class ApplicationController < ActionController::Base
  protect_from_forgery
  after_filter { flash.discard if request.xhr? }
end
