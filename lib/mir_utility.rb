require 'singleton'
require 'soap/header/simplehandler'

module MirUtility
  MONTHS = {
    0 => "JAN",
    1 => "FEB",
    2 => "MAR",
    3 => "APR",
    4 => "MAY",
    5 => "JUN",
    6 => "JUL",
    7 => "AUG",
    8 => "SEP",
    9 => "OCT",
    10 => "NOV",
    11 => "DEC"
  }

  STATE_CODES = { 'Alabama' => 'AL', 'Alaska' => 'AK', 'Arizona' => 'AZ', 'Arkansas' => 'AR', 'California' => 'CA', 'Colorado' => 'CO', 'Connecticut' => 'CT', 'Delaware' => 'DE', 'Florida' => 'FL', 'Georgia' => 'GA', 'Hawaii' => 'HI', 'Idaho' => 'ID', 'Illinois' => 'IL', 'Indiana' => 'IN', 'Iowa' => 'IA', 'Kansas' => 'KS', 'Kentucky' => 'KY', 'Louisiana' => 'LA', 'Maine' => 'ME', 'Maryland' => 'MD', 'Massachusetts' => 'MA', 'Michigan' => 'MI', 'Minnesota' => 'MN', 'Mississippi' => 'MS', 'Missouri' => 'MO', 'Montana' => 'MT', 'Nebraska' => 'NE', 'Nevada' => 'NV', 'New Hampshire' => 'NH', 'New Jersey' => 'NJ', 'New Mexico' => 'NM', 'New York' => 'NY', 'North Carolina' => 'NC', 'North Dakota' => 'ND', 'Ohio' => 'OH', 'Oklahoma' => 'OK', 'Oregon' => 'OR', 'Pennsylvania' => 'PA', 'Puerto Rico' => 'PR', 'Rhode Island' => 'RI', 'South Carolina' => 'SC', 'South Dakota' => 'SD', 'Tennessee' => 'TN', 'Texas' => 'TX', 'Utah' => 'UT', 'Vermont' => 'VT', 'Virginia' => 'VA', 'Washington' => 'WA', 'Washington DC' => 'DC', 'West Virginia' => 'WV', 'Wisconsin' => 'WI', 'Wyoming' => 'WY', 'Alberta' => 'AB', 'British Columbia' => 'BC', 'Manitoba' => 'MB', 'New Brunswick' => 'NB', 'Newfoundland and Labrador' => 'NL', 'Northwest Territories' => 'NT', 'Nova Scotia' => 'NS', 'Nunavut' => 'NU', 'Ontario' => 'ON', 'Prince Edward Island' => 'PE', 'Quebec' => 'QC', 'Saskatchewan' => 'SK', 'Yukon' => 'YT' }

  def self.canonical_url(url)
    (url + '/').gsub(/\/\/$/,'/')
  end

  def self.destroy_old_sessions
    ActiveRecord::SessionStore::Session.destroy_all(
      ['updated_at < ?', 1.day.ago.utc]
    )
  end

  # When Slug.normalize just isn't good enough...
  def self.normalize_slug(text)
    _normalized = Slug.normalize(text)
    _normalized.gsub!('-', '_')    # change - to _
    _normalized.gsub!(/[_]+/, '_') # truncate multiple _
    _normalized
  end

  def self.state_name_for(abbreviation)
    STATE_CODES.value?(abbreviation.to_s.upcase) && STATE_CODES.find{|k,v| v == abbreviation.to_s.upcase}[0]
  end

  module CoreExtensions
    module String
      # Add whatever helpers you want, then wrap any methods that you want from the
      #   ActionView::Helpers::Foo class
      module NumberHelper
        def number_to_phone(s, options = {})
          StringHelperSingleton.instance.number_to_phone(s, options)
        end
      end
    end
  end

end

class ActionController::Base
  include MirUtility
  require 'socket'

  def self.local_ip
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end

  # Returns a sanitized column parameter suitable for SQL order-by clauses.
  def sanitize_by_param(allowed=[], default='id')
    sanitize_params params && params[:by], allowed, default
  end

  # Returns a sanitized direction parameter suitable for SQL order-by clauses.
  def sanitize_dir_param(default='ASC')
    sanitize_params params && params[:dir], ['ASC', 'DESC'], default
  end

  # Use this method to prevent SQL injection vulnerabilities by verifying that a user-provided
  # parameter is on a whitelist of allowed values.
  #
  # Accepts a value, a list of allowed values, and a default value.
  # Returns the value if allowed, otherwise the default.
  def sanitize_params(supplied='', allowed=[], default=nil)
    raise ArgumentError, "A default value is required." unless default
    return default.to_s if supplied.blank? || allowed.blank? || ! allowed.map{ |x| x.to_s }.include?(supplied.to_s)
    return supplied
  end
end

module ActiveRecord::Validations::ClassMethods

  # Overrides validates associates.
  # We do this to allow more better error messages to bubble up from associated models.
  # Adapted from thread at http://pivotallabs.com/users/nick/blog/articles/359-alias-method-chain-validates-associated-informative-error-message
  def validates_associated(*associations)
    # These configuration lines are required if your going to use any conditionals with the validates associated - Rails 2.2.2 safe!
    configuration = { :message => I18n.translate('activerecord.errors.messages'), :on => :save }
    configuration.update(associations.extract_options!)
    associations.each do |association|
      class_eval do
        validates_each(associations,configuration) do |record, associate_name, value|
          associates = record.send(associate_name)
          associates = [associates] unless associates.respond_to?('each')
          associates.each{ |associate| associate.errors.each{ |key, value2| record.errors.add("", "#{value2}") } if associate && !associate.valid? }
        end
      end
    end
  end
end

class ActiveRecord::Base
  include MirUtility

  #FIXME Extending AR in this way will stop working under Rails 2.3.2 for some reason.

  named_scope :order_by, lambda{ |col, dir| {:order => (col.blank?) ? ( (dir.blank?) ? 'id' : dir ) : "#{col} #{dir}"} }
  named_scope :limit, lambda { |num| { :limit => num } }

  # TODO: call the column_names class method on the subclass
  #  named_scope :sort_by, lambda{ |col, dir| {:order => (col.blank?) ? ( (dir.blank?) ? (Client.column_names.include?('name') ? 'name' : 'id') : h(dir) ) : "#{h(col)} #{h(dir)}"} }

  # Returns an array of SQL conditions suitable for use with ActiveRecord's finder.
  # valid_criteria is an array of valid search fields.
  # pairs is a hash of field names and values.
  def self.search_conditions( valid_search_criteria, pairs, operator = 'OR' )
    if valid_search_criteria.detect{ |_c| ! pairs[_c].blank? } || ! pairs[:query].blank?
      _conditions = []
      _or_clause = ''
      _or_clause_values = []
      _int_terms = {}
      _text_terms = {}

      # build or clause for keyword search
      unless pairs[:query].blank? || ! self.respond_to?(:flattened_content)
        pairs[:query].split(' ').each do |keyword|
          _or_clause += 'flattened_content LIKE ? OR '
          _or_clause_values << "%#{keyword}%"
        end

        _or_clause.gsub!( / OR $/, '')
      end

      # iterate across each valid search field
      valid_search_criteria.each do |_field|
        # build or clause for keyword search
        unless pairs[:query].blank? || self.respond_to?(:flattened_content)
          pairs[:query].split(' ').each do |keyword|
            _or_clause += "#{_field} LIKE ? OR "
            _or_clause_values << "%#{keyword}%"
          end
        end

        # build hashes of integer and/or text search fields and values for each non-blank param
        if ! pairs[_field].blank?
          _field.to_s =~ /^id$|_id$|\?$/ ? _int_terms[_field.to_s.gsub('?', '')] = pairs[_field] : _text_terms[_field] = pairs[_field]
        end
      end

      _or_clause.gsub!( / OR $/, '')

      # convert the hash to parametric SQL
      if _or_clause.blank?
        _conditions = sql_conditions_for( _int_terms, _text_terms, nil, operator )
      elsif _int_terms.keys.empty? && _text_terms.keys.empty?
        _conditions = [ _or_clause ]
      else
        _conditions = sql_conditions_for( _int_terms, _text_terms, _or_clause, operator )
      end

      # add integer values
      _int_terms.keys.each{ |key| _conditions << _int_terms[key] }
      # add wildcard-padded values
      _text_terms.keys.each{ |key| _conditions << "%#{_text_terms[key]}%" }

      unless _or_clause_values.empty?
        # add keywords
        _conditions += _or_clause_values
      end

      return _conditions
    else
      return nil
    end
  end

  def self.to_option_values
    self.all.sort_by{ |x| x.name }.map{ |x| [x.name, x.id] }
  end

  # Strips the specified attribute's value.
  def strip(attribute)
    value = self[attribute]
    self.send("#{attribute}=", value && value.strip)
  end

  private

  def self.sql_conditions_for( integer_fields, text_fields, or_clause = nil, operator = 'OR' )
    if integer_fields.empty? && ! text_fields.empty?
      [ text_fields.keys.map{ |k| k } * " LIKE ? #{operator} " + ' LIKE ?' + (or_clause ? " #{operator} #{or_clause}" : '') ]
    elsif ! integer_fields.empty? && text_fields.empty?
      [ integer_fields.keys.map{ |k| k } * " = ? #{operator} " + ' = ?' + (or_clause ? " #{operator} #{or_clause}" : '') ]
    else
      [ integer_fields.keys.map{ |k| k } * " = ? #{operator} " + " = ? #{operator} " + text_fields.keys.map{ |k| k } * " LIKE ? #{operator} " + ' LIKE ?' + (or_clause ? " #{operator} #{or_clause}" : '') ]
    end
  end
end

module ApplicationHelper

  SELECT_PROMPT = 'Select...'
  SELECT_PROMPT_OPTION = "<option value=''>#{SELECT_PROMPT}</option>"

  def action?( expression )
    !! ( expression.class == Regexp ? controller.action_name =~ expression : controller.action_name == expression )
  end

  # Formats an array with HTML line breaks, or the specified delimiter.
  def array_to_lines(array, delimiter = '<br />')
    return unless array.is_a?(Array)
    array.blank? ? nil : array * delimiter
  end

  def checkmark
    %{<div class="checkmark"></div>}
  end

  def controller?( expression )
    !! ( expression.class == Regexp ? controller.controller_name =~ expression : controller.controller_name == expression )
  end

  # Display CRUD icons or links, according to setting in use_crud_icons method.
  #
  # In application_helper.rb:
  #
  #   def use_crud_icons
  #     true
  #   end
  #
  # Then use in index views like this:
  #
  # <td class="crud_links"><%= crud_links(my_model, 'my_model', [:show, :edit, :delete]) -%></td>
  #
  def crud_links(model, instance_name, actions, args={})
    _html = ''
    _path = args.delete(:path) || model
    _edit_path = args.delete(:edit_path) || eval("edit_#{instance_name}_path(model)") if actions.include?(:edit)
    _options = args.empty? ? '' : ", #{args.map{|k,v| ":#{k} => #{v}"}}"

    if use_crud_icons
      _html << link_to(image_tag('icons/view.png', :class => 'crud_icon', :width => 14, :height => 14), _path, :title => "View#{_options}") if actions.include?(:show)
      _html << link_to(image_tag('icons/edit.png', :class => 'crud_icon', :width => 14, :height => 14), _edit_path, :title => "Edit#{_options}") if actions.include?(:edit)
      _html << link_to(image_tag('icons/delete.png', :class => 'crud_icon', :width => 14, :height => 14), _path, :confirm => 'Are you sure? This action cannot be undone.', :method => :delete, :title => "Delete#{_options}") if actions.include?(:delete)
    else
      _html << link_to('View', _path, :title => 'View', :class => "crud_link#{_options}") if actions.include?(:show)
      _html << link_to('Edit', _edit_path, :title => 'Edit', :class => "crud_link#{_options}") if actions.include?(:edit)
      _html << link_to('Delete', _path, :confirm => 'Are you sure? This action cannot be undone.', :method => :delete, :title => 'Delete', :class => "crud_link#{_options}") if actions.include?(:delete)
    end

    _html
  end

  # Display CRUD icons or links, according to setting in use_crud_icons method.
  # This method works with nested resources.
  # Use in index views like this:
  #
  # <td class="crud_links"><%= crud_links_for_nested_resource(@my_model, my_nested_model, 'my_model', 'my_nested_model', [:show, :edit, :delete]) -%></td>
  #
  def crud_links_for_nested_resource(model, nested_model, model_instance_name, nested_model_instance_name, actions, args={})
    crud_links model, model_instance_name, actions, args.merge(:edit_path => eval("edit_#{model_instance_name}_#{nested_model_instance_name}_path(model, nested_model)"), :path => [model, nested_model])
  end

  # DRY way to return a legend tag that renders correctly in all browsers. This variation allows
  # for more "stuff" inside the legend tag, e.g. expand/collapse controls, without having to worry
  # about escape sequences.
  #
  # Sample usage:
  #
  #   <%- legend_block do -%>
  #     <span id="hide_or_show_backlinks" class="show_link" style="background-color: #999999;
  #     border: 1px solid #999999;" onclick="javascript:hide_or_show('backlinks');"></span>Backlinks (<%=
  #     @google_results.size -%>)
  #   <%- end -%>
  #
  def legend_block(&block)
    concat content_tag(:div, capture(&block), :class => "faux_legend")
  end

  # DRY way to return a legend tag that renders correctly in all browsers
  #
  # Sample usage:
  #
  #   <%= legend_tag "Report Criteria" -%>
  #
  # Sample usage with help text:
  #
  #   <%= legend_tag "Report Criteria", :help => "Some descriptive copy here." -%>
  #     <span id="hide_or_show_backlinks" class="show_link" style="background-color: #999999;
  #     border: 1px solid #999999;" onclick="javascript:hide_or_show('backlinks');"></span>Backlinks (<%=
  #     @google_results.size -%>)
  #   <%- end -%>
  #
  # Recommended CSS to support display of help icon and text:
  #
  #     .help_icon {
  #       display: block;
  #       float: left;
  #       margin-top: -16px;
  #       margin-left: 290px;
  #       border-left: 1px solid #444444;
  #       padding: 3px 6px;
  #       cursor: pointer;
  #     }
  #     
  #     div.popup_help {
  #       color: #666666;
  #       width: 98%;
  #       background: #ffffff;
  #       padding: 1em;
  #       border: 1px solid #999999;
  #       margin: 1em 0em;
  #     }
  #     
  def legend_tag(text, args={})
    args[:id] ||= text.downcase.gsub(/ /,'_')
    if args[:help]
      _html = %{<div id="#{args[:id]}" class="faux_legend">#{text}<span class="help_icon" onclick="$('#{args[:id]}_help').toggle();">?</span></div>\r}
      _html << %{<div id="#{args[:id]}_help" class="popup_help" style="display: none;">#{args[:help]}<br /></div>\r}
    else
      _html = %{<div id="#{args[:id]}" class="faux_legend">#{text}</div>\r}
    end
    _html.gsub!(/ id=""/,'')
    _html.gsub!(/ class=""/,'')
    _html
  end

  def meta_description(content=nil)
    content_for(:meta_description) { content } unless content.blank?
  end

  def meta_keywords(content=nil)
    content_for(:meta_keywords) { content } unless content.blank?
  end

  def models_for_select( models, label = 'name' )
    models.map{ |m| [m[label], m.id] }.sort_by{ |e| e[0] }
  end

  def options_for_array( a, selected = nil, prompt = SELECT_PROMPT )
    "<option value=''>#{prompt}</option>" + a.map{ |_e| _flag = _e[0].to_s == selected ? 'selected="1"' : ''; _e.is_a?(Array) ? "<option value=\"#{_e[0]}\" #{_flag}>#{_e[1]}</option>" : "<option>#{_e}</option>" }.to_s
  end

  # Create a link that is opaque to search engine spiders.
  def obfuscated_link_to(path, image, label, args={})
    _html = %{<form action="#{path}" method="get" class="obfuscated_link">}
    _html << %{ <fieldset><input alt="#{label}" src="#{image}" type="image" /></fieldset>}
    args.each{ |k,v| _html << %{  <div><input id="#{k.to_s}" name="#{k}" type="hidden" value="#{v}" /></div>} }
    _html << %{</form>}
    _html
  end

  # Wraps the given HTML in Rails' default style to highlight validation errors, if any.
  def required_field_helper( model, element, html )
    if model && ! model.errors.empty? && element.is_required
      return content_tag( :div, html, :class => 'fieldWithErrors' )
    else
      return html
    end
  end

  # Use on index pages to create dropdown list of filtering criteria.
  # Populate the filter list using a constant in the model corresponding to named scopes.
  #
  # Usage:
  #
  # - item.rb:
  #
  #     named_scope :active,   :conditions => { :is_active => true }
  #     named_scope :inactive, :conditions => { :is_active => false }
  #
  #     FILTERS = [
  #       {:scope => "all",       :label => "All"},
  #       {:scope => "active",    :label => "Active Only"},
  #       {:scope => "inactive",  :label => "Inactive Only"}
  #     ]
  #
  # - items/index.html.erb:
  #
  #     <%= select_tag_for_filter("items", @filters, params) -%>
  #
  # - items_controller.rb:
  #
  #     def index
  #       @filters = Item::FILTERS
  #       if params[:show] && params[:show] != "all" && @filters.collect{|f| f[:scope]}.include?(params[:show])
  #         @items = eval("@items.#{params[:show]}.order_by(params[:by], params[:dir])")
  #       else
  #         @items = @items.order_by(params[:by], params[:dir])
  #       end
  #       ...
  #     end
  #
  def select_tag_for_filter(model, filters, params)
    return unless model && ! filters.blank?
    _html = %{<label for="show">Show:</label><br /><select name="show" id="show" onchange="window.location='#{eval("#{model}_url")}?#{params.to_params}&show=' + this.value">}

    filters.each do |pair|
      _html = %{#{_html}<option value="#{pair[:scope]}"}
      if params[:show] == pair[:scope] || (params[:show].blank? && pair[:scope] == "all")
        _html = %{#{_html} selected="selected"}
      end
      _html = %{#{_html}>#{pair[:label]}</option>}
    end
    _html = %{#{_html}</select>}
  end

  # Returns a link_to tag with sorting parameters that can be used with ActiveRecord.order_by.
  #
  # To use standard resources, specify the resources as a plural symbol:
  #   sort_link(:users, 'email', params)
  #
  # To use resources aliased with :as (in routes.rb), specify the aliased route as a string.
  #   sort_link('users_admin', 'email', params)
  #
  # You can override the link's label by adding a labels hash to your params in the controller:
  #   params[:labels] = {'user_id' => 'User'}
  def sort_link(model, field, params, html_options={})
    if (field.to_sym == params[:by] || field == params[:by]) && params[:dir] == "ASC"
      classname = "arrow-asc"
      dir = "DESC"
    elsif (field.to_sym == params[:by] || field == params[:by])
      classname = "arrow-desc"
      dir = "ASC"
    else
      dir = "ASC"
    end

    options = {
      :anchor => html_options[:anchor],
      :by => field,
      :dir => dir,
      :query => params[:query],
      :show => params[:show]
    }

    options[:show] = params[:show] unless params[:show].blank? || params[:show] == 'all'

    html_options = {
      :class => "#{classname} #{html_options[:class]}",
      :style => "color: white; font-weight: #{params[:by] == field ? "bold" : "normal"}; #{html_options[:style]}",
      :title => "Sort by this field"
    }

    field_name = params[:labels] && params[:labels][field] ? params[:labels][field] : field.titleize

    _link = model.is_a?(Symbol) ? eval("#{model}_url(options)") : "/#{model}?#{options.to_params}"
    link_to(field_name, _link, html_options)
  end

  # Tabbed interface helpers =======================================================================

  # Returns formatted tabs with appropriate JS for activation. Use in conjunction with tab_body.
  #
  # Usage:
  #
  #   <%- tabset do -%>
  #     <%= tab_tag :id => 'ppc_ads', :label => 'PPC Ads', :state => 'active' %>
  #     <%= tab_tag :id => 'budget' %>
  #     <%= tab_tag :id => 'geotargeting' %>
  #   <%- end -%>
  #
  def tabset(&proc)
    concat %{
      <div class="jump_links">
        <ul>
    }
    yield
    concat %{
        </ul>
      </div>
      <br style="clear: both;" /><br />
      <input type="hidden" id="show_tab" />
      <script type="text/javascript">
        function hide_all_tabs() { $$('.tab_block').invoke('hide'); }
        function activate_tab(tab) {
          $$('.tab_control').each(function(elem){ elem.className = 'tab_control'});
          $('show_' + tab).className = 'tab_control active';
          hide_all_tabs();
          $(tab).toggle();
          $('show_tab').value = tab
        }
        function sticky_tab() { if (location.hash) { activate_tab(location.hash.gsub('#','')); } }
        Event.observe(window, 'load', function() { sticky_tab(); });
      </script>
    }
  end

  # Returns a tab body corresponding to tabs in a tabset. Make sure that the id of the tab_body
  # matches the id provided to the tab_tag in the tabset block.
  #
  # Usage:
  #
  #   <%- tab_body :id => 'ppc_ads', :label => 'PPC Ad Details' do -%>
  #     PPC ads form here.
  #   <%- end -%>
  #
  #   <%- tab_body :id => 'budget' do -%>
  #     Budget form here.
  #   <%- end -%>
  #
  #   <%- tab_body :id => 'geotargeting' do -%>
  #     Geotargeting form here.
  #   <%- end -%>
  #
  def tab_body(args, &proc)
    concat %{<div id="#{args[:id]}" class="tab_block form_container" style="display: #{args[:display] || 'none'};">}
    concat %{#{legend_tag args[:label] || args[:id].titleize }}
    concat %{<a name="#{args[:id]}"></a><br />}
    yield
    concat %{</div>}
  end

  # Returns the necessary HTML for a particular tab. Use inside a tabset block.
  # Override the default tab label by specifying a :label parameter.
  # Indicate that the tab should be active by setting its :state to 'active'.
  # (NOTE: You must define a corresponding  CSS style for active tabs.)
  #
  # Usage:
  #
  #   <%= tab_tag :id => 'ppc_ads', :label => 'PPC Ads', :state => 'active' %>
  #
  def tab_tag(args, *css_class)
    %{<li id="show_#{args[:id]}" class="tab_control #{args[:state]}" onclick="window.location='##{args[:id]}'; activate_tab('#{args[:id]}');">#{args[:label] || args[:id].to_s.titleize}</li>}
  end

  # ================================================================================================

  def tag_for_collapsible_row(obj, params)
    _html = ""
    if obj && obj.respond_to?(:parent) && obj.parent
      _html << %{<tr class="#{obj.class.name.downcase}_#{obj.parent.id} #{params[:class]}" style="display: none; #{params[:style]}">}
    else
      _html << %{<tr class="#{params[:class]}" style="#{params[:style]}">}
    end
    _html
  end

  def tag_for_collapsible_row_control(obj)
    _base_id = "#{obj.class.name.downcase}_#{obj.id}"
    _html = %{<div id="hide_or_show_#{_base_id}" class="show_link" style="background-color: #999999; border: 1px solid #999999;" onclick="javascript:hide_or_show('#{_base_id}');"></div>}
  end

  # Create a set of tags for displaying a field label with inline help.
  # Field label text is appended with a ? icon, which responds to a click
  # by showing or hiding the provided help text.
  #
  # Sample usage:
  #
  #   <%= tag_for_label_with_inline_help 'Relative Frequency', 'rel_frequency', 'Relative frequency of search traffic for this keyword across multiple search engines, as measured by WordTracker.' %>
  #
  # Yields:
  #
  #   <label for="rel_frequency">Relative Frequency: <%= image_tag "/images/help_icon.png", :onclick => "$('rel_frequency_help').toggle();", :class => 'inline_icon' %></label><br />
  #   <div class="inline_help" id="rel_frequency_help" style="display: none;">
  #     <p>Relative frequency of search traffic for this keyword across multiple search engines, as measured by WordTracker.</p>
  #   </div>
  def tag_for_label_with_inline_help( label_text, field_id, help_text )
    _html = ""
    _html << %{<label for="#{field_id}">#{label_text}}
    _html << %{<img src="/images/icons/help_icon.png" onclick="$('#{field_id}_help').toggle();" class='inline_icon' />}
    _html << %{</label><br />}
    _html << %{<div class="inline_help" id="#{field_id}_help" style="display: none;">}
    _html << %{<p>#{help_text}</p>}
    _html << %{</div>}
    _html
  end

  # Create a set of tags for displaying a field label followed by instructions.
  # The instructions are displayed on a new line following the field label.
  #
  # Usage:
  #
  #   <%= tag_for_label_with_instructions 'Status', 'is_active', 'Only active widgets will be visible to the public.' %>
  #
  # Yields:
  #
  #   <label for="is_active">
  #     Status<br />
  #     <span class="instructions">Only active widgets will be visible to the public.</span>
  #   <label><br />
  def tag_for_label_with_instructions( label_text, field_id, instructions )
    _html = ""
    _html << %{<label for="#{field_id}">#{label_text}}
    _html << %{<span class="instructions">#{instructions}</span>}
    _html << %{</label><br />}
    _html
  end

end

class Array
  def mean
    self.inject(0){ |sum, x| sum += x } / self.size.to_f
  end

  def count
    self.size
  end

end

module Enumerable
  def to_histogram
    inject(Hash.new(0)) { |h,x| h[x] += 1; h }
  end
end

class Fixnum
  include MirUtility

  # Given a number of seconds, convert into a string like HH:MM:SS
  def to_hrs_mins_secs
    _now = DateTime.now
    _d = Date::day_fraction_to_time((_now + self.seconds) - _now)
    "#{sprintf('%02d',_d[0])}:#{sprintf('%02d',_d[1])}:#{sprintf('%02d',_d[2])}"
  end
end

class Float
  include MirUtility
  def to_nearest_tenth
    sprintf("%.1f", self).to_f
  end
end

class Hash
  def to_params
    params = ''
    stack = []

    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      elsif v.is_a?(Array)
        stack << [k,Hash.from_array(v)]
      else
        params << "#{k}=#{v}&"
      end
    end

    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end

    params.chop!
    params
  end

  def to_sql( operator = 'AND' )
    _sql = self.keys.map do |_key|
      _value = self[_key].is_a?(Fixnum) ? self[_key] : "'#{self[_key]}'"
      self[_key].nil? ? '1 = 1' : "#{_key} = #{_value}"
    end
    _sql * " #{operator} "
  end

  def self.from_array(array = [])
    h = Hash.new
    array.size.times{ |t| h[t] = array[t] }
    h
  end

end

# Helper class for SOAP headers.
class Header < SOAP::Header::SimpleHandler
	def initialize(tag, value)
		super(XSD::QName.new(nil, tag))
		@tag = tag
		@value = value
	end

	def on_simple_outbound
		@value
	end
end

class String

  # Bring in support for view helpers
  include MirUtility::CoreExtensions::String::NumberHelper

  # General methods

  def capitalize_words
    self.downcase.gsub(/\b([a-z])/) { $1.capitalize }.gsub( "'S", "'s" )
  end

  # Address methods

  def expand_address_abbreviations
    _address = self.strip.capitalize_words

    # NOTE: DO NOT rearrange the replace sequences; order matters!

    # streets
    _address.gsub!( /\b(ave|av)\.?\b/i, 'Avenue ' )
    _address.gsub!( /\b(blvd|blv|bld|bl)\.?\b/i, 'Boulevard ' )
    _address.gsub!( /\bcr\.?\b/i, 'Circle ' )
    _address.gsub!( /\bctr\.?\b/i, 'Center ' )
    _address.gsub!( /\b(crt|ct)\.?\b/i, 'Court ' )
    _address.gsub!( /\bdr\.?\b/i, 'Drive ' )
    _address.gsub!( /\b(expressw|expw|expy)\.?\b/i, 'Expressway ' )
    _address.gsub!( /\bfrwy\.?\b/i, 'Freeway ' )
    _address.gsub!( /\bhwy\.?\b/i, 'Highway ' )
    _address.gsub!( /\bln\.?\b/i, 'Lane ' )
    _address.gsub!( /\b(prkwy|pkwy|pkw|pky)\.?\b/i, 'Parkway ' )
    _address.gsub!( /\bpk\.?\b/i, 'Pike ' )
    _address.gsub!( /\bplz\.?\b/i, 'Plaza ' )
    _address.gsub!( /\bpl\.?\b/i, 'Place ' )
    _address.gsub!( /\brd\.?\b/i, 'Road ' )
    _address.gsub!( /\b(rte|rt)\.?\b/i, 'Route ' )
    _address.gsub!( /\bste\.?\b/i, 'Suite ' )
    _address.gsub!( /\bst\.?\b/i, 'Street ' )
    _address.gsub!( /\btrpk\.?\b/i, 'Turnpike ' )
    _address.gsub!( /\btr\.?\b/i, 'Trail ' )

    # directions
    _address.gsub!( /\bN\.?e\.?\b/i, 'Northeast ' )
    _address.gsub!( /\bS\.?e\.?\b/i, 'Southeast ' )
    _address.gsub!( /\bS\.?w\.?\b/i, 'Southwest ' )
    _address.gsub!( /\bN\.?w\.?\b/i, 'Northwest ' )
    _address.gsub!( /\bN\.?\b/, 'North ' )
    _address.gsub!( /\bE\.?\b/, 'East ' )
    _address.gsub!( /\bS\.?\b/, 'South ' )
    _address.gsub!( /\bW\.?\b/, 'West ' )
    _address.gsub!( '.', '' )
    _address.gsub!( / +/, ' ' )
    _address.strip
  end

  def formatted_phone
    if self
      # remove non-digit characters
      _self = self.gsub(/[\(\) -]+/, '')
      # format as phone if 10 digits are left
      return number_to_phone(_self, :area_code => true ) if !! (_self =~ /[0-9]{10}/)
    end

    self
  end

  def formatted_zip
    return if self.blank?
    self.gsub!( /[\(\) -]+/, '' )
    self.size == 9 ? "#{self[0 .. 4]}-#{self[5 .. -1]}" : self
  end

  # Time methods

  def to_12_hour_time
    (self == '0' || self.blank?) ? nil : Time.parse( "#{self[0..-3]}:#{self[-2..-1]}" ).to_s( :time ).gsub(/^0/, '')
  end

  # URL methods

  # Prefixes the given url with 'http://'.
  def add_http_prefix
    return if self.blank?
    _uri = self.to_uri
    return self if _uri.nil? || _uri.is_a?(URI::FTP) || _uri.is_a?(URI::HTTP) || _uri.is_a?(URI::HTTPS) || _uri.is_a?(URI::LDAP) || _uri.is_a?(URI::MailTo)
    "http://#{self}"
  end

  # Returns true if a given string begins with http:// or https://.
  def has_http?
    !! (self =~ /^http[s]?:\/\/.+/)
  end

  # Returns true if a given string has a trailing slash.
  def has_trailing_slash?
    !! (self =~ /\/$/)
  end

  # Returns true if a given string refers to an HTML page.
  def is_page?
    !! (self =~ /\.htm[l]?$/)
  end

  # Returns the host from a given URL string; returns nil if the string is not a valid URL.
  def to_host
    _uri = self.to_uri
    _uri ? _uri.host : nil
  end

  # Returns a URI for the given string; nil if the string is invalid.
  def to_uri
    begin
      _uri = URI.parse self
    rescue URI::InvalidURIError
      RAILS_DEFAULT_LOGGER.warn "#{self} is an invalid URI!"
    end

    _uri
  end

  # Returns true if the given string is a valid URL.
  def valid_http_url?
    self.scan(/:\/\//).size == 1 && self.to_uri.is_a?(URI::HTTP)
  end
end

class StringHelperSingleton
  include Singleton
  include ActionView::Helpers::NumberHelper
end

class TrueClass
  def to_i; 1; end
end

class FalseClass
  def to_i; 0; end
end
