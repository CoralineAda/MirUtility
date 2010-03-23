# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

include MirUtility

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time

  prepend_before_filter do |controller|
    # enable protection only when sessions are enabled
    controller.class.allow_forgery_protection = controller.session_enabled?
    @session_enabled = controller.session_enabled?
  end

  unless ActionController::Base.consider_all_requests_local
    rescue_from ActionController::RoutingError, ActionController::UnknownAction, ActionController::UnknownController, ActiveRecord::RecordNotFound, :with => :render_404
    rescue_from Exception do |@exception|
      @exception.message =~ /Couldn't find .+ ID|Missing template|No route matches|No action responded/ ? render_404 : render_500
    end
  end

  protect_from_forgery # :secret => '039ad6535a9b90fb3bf4b2b653f97452'

end
