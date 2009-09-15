# == Configuration
#
# === Configure your application to default to the custom form builder
#
# In app/controllers/application_controller.rb:
#
#   class ApplicationController < ActionController::Base
#     ActionView::Base.default_form_builder = MirFormBuilder
#
# == Usage
#
# === Default form field with label:
#
#   <%= f.text_field :last_name -%>
#
# Returns:
#
#   <fieldset>
#     <label for="user_last_name">Last Name</label><br />
#     <input id="user_last_name" name="user[last_name]" size="30" type="text" />
#   </fieldset>
#
# === Form field with custom label:
#
#   <%= f.text_field :first_name, :label => 'Custom' -%>
#
# Returns:
#
#   <fieldset>
#     <label for="user_first_name">Custom</label><br />
#     <input id="user_first_name" name="user[first_name]" size="30" type="text" />
#   </fieldset>
#
# === Form field with inline help (? icon which reveals help content when clicked):
#
#   <%= f.password_field :password %>
#
# Returns:
#
#   <fieldset>
#     <label for="password">Password: <img src="/images/icons/help_icon.png"
#     onclick="$('password_help').toggle();" class='inline_icon' /></label><br />
#     <div class="inline_help" id="password_help" style="display: none;">
#       <p>Here are some detailed instructions on valid passwords.</p>
#     </div>
#     <input id="user_password" name="user[password]" size="30" type="password" />
#   </fieldset>
#
# === Form field with instructions (show immediately below the label):
#
#   <%= f.password_field :password_confirmation %>
#
# Returns:
#
#   <fieldset>
#     <label for="password_confirmation">
#       Confirm Password:
#       <span class="instructions">Enter your password again to confirm.</span>
#     </label><br />
#     <input id="user_password_confirmation" name="user[password_confirmation]" size="30" type="password" />
#   </fieldset>
#
# === Check box with label in addition to checkbox value text
# (E.g. 'Foo' appears above the checkbox, and 'Something' next to it):
#
#   <%= f.check_box :foo, :inline_label => 'Something' -%>
#
# Returns:
#
#   <fieldset>
#     <label for="user_foo">Foo</label><br />
#     <input name="user[foo]" type="hidden" value="0" />
#     <input id="user_foo" name="user[foo]" type="checkbox" value="1" />
#     <label class="inline" for="user_foo">Something</label><br style='clear: both;'/><br />
#   </fieldset>
#
# == Troubleshooting
#
# If you're seeing double form labels, it's because you still have <%= label -%> elements in your forms.
#
class MirFormBuilder < ActionView::Helpers::FormBuilder

  include ApplicationHelper
  
  helpers = field_helpers +
    %w{date_select datetime_select time_select} +
    %w{collection_select select country_select time_zone_select} -
    %w{hidden_field label fields_for}
  
  helpers.each do |name|
    
    define_method(name) do |field, *args|
      options = args.last.is_a?(Hash) ? args.pop : {}
      _label_text = options[:label] || field.to_s.humanize.capitalize_words
      if options[:instructions]
        _label = tag_for_label_with_instructions(_label_text, field, options[:instructions])
      elsif options[:help]
        _label = tag_for_label_with_inline_help(_label_text, field, options[:help])
      else
        _label = label(field, _label_text) + "<br />"
      end
      _inline_label = options[:inline_label] ? label(field, options[:inline_label], :class => 'inline') + "<br style='clear: both;'/><br />" : ""
      options.delete(:instructions)
      options.delete(:help)
      options.delete(:inline_label)
      @template.content_tag(:fieldset, _label + super + _inline_label)
    end
  
  end

end
