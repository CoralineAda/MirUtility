# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ReCaptcha::ViewHelper

  # HTML methods

  def breadcrumbs
  
    return if controller?('home') && action?(/home|index/)

    html = [ link_to('Home', root_path) ]

    # level 1
    html << link_to( 'My Profile', current_user ) if viewing_my_profile?
    html << link_to( 'Users', users_path ) if controller?('users') && ! viewing_my_profile?

    # level 2

    # level 3

    html * ' &gt; '
  end

  # Replace show/edit/delete links with icons in index views?
  def use_crud_icons
    true
  end
  
  # utility methods

  def set_active_tab
    # default to controller name
    @active_tab = controller.controller_name

    # exceptions
    @active_tab = 'my_profile' if viewing_my_profile?
  end

  def tab_for(link, link_title, tab_name, *disabled)
    js_link = "onclick=\"javascript:window.location='#{link}'\""
    js_link = "onclick=\"#{feature_teaser_popup}\"" unless disabled.empty?
    html = "<li id=\"#{tab_name}\" class=\"" + (@active_tab == tab_name ? 'here' : '') + "\"" + js_link + ">"
    html << link_to( link_title, link, :title => link_title, :onclick => disabled.empty? ? "" : feature_teaser_popup )
    html << "</li>"
  end

  def title(page_title = nil)
    if page_title.nil?
      content_for(:title) { 'SEO Logic' }
      content_for(:page_title) {  }
    else
      content_for(:title) { page_title + ' - SEO Logic' }
      content_for(:page_title) { page_title }
    end
  end

  def viewing_my_profile?
    controller?('users') && action?(/edit|show/) && current_user.id == params[:id].to_i
  end
end
