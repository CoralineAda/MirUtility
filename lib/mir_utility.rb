require 'singleton'

module Utility

  require 'soap/header/simplehandler'

  STATE_CODES = {
    'Alabama' => 'AL',
    'Alaska' => 'AK',
    'Arizona' => 'AZ',
    'Arkansas' => 'AR',
    'California' => 'CA',
    'Colorado' => 'CO',
    'Connecticut' => 'CT',
    'Delaware' => 'DE',
    'Florida' => 'FL',
    'Georgia' => 'GA',
    'Hawaii' => 'HI',
    'Idaho' => 'ID',
    'Illinois' => 'IL',
    'Indiana' => 'IN',
    'Iowa' => 'IA',
    'Kansas' => 'KS',
    'Kentucky' => 'KY',
    'Louisiana' => 'LA',
    'Maine' => 'ME',
    'Maryland' => 'MD',
    'Massachusetts' => 'MA',
    'Michigan' => 'MI',
    'Minnesota' => 'MN',
    'Mississippi' => 'MS',
    'Missouri' => 'MO',
    'Montana' => 'MT',
    'Nebraska' => 'NE',
    'Nevada' => 'NV',
    'New Hampshire' => 'NH',
    'New Jersey' => 'NJ',
    'New Mexico' => 'NM',
    'New York' => 'NY',
    'North Carolina' => 'NC',
    'North Dakota' => 'ND',
    'Ohio' => 'OH',
    'Oklahoma' => 'OK',
    'Oregon' => 'OR',
    'Pennsylvania' => 'PA',
    'Puerto Rico' => 'PR',
    'Rhode Island' => 'RI',
    'South Carolina' => 'SC',
    'South Dakota' => 'SD',
    'Tennessee' => 'TN',
    'Texas' => 'TX',
    'Utah' => 'UT',
    'Vermont' => 'VT',
    'Virginia' => 'VA',
    'Washington' => 'WA',
    'Washington DC' => 'DC',
    'West Virginia' => 'WV',
    'Wisconsin' => 'WI',
    'Wyoming' => 'WY',

    # canada
    'Alberta' => 'AB',
    'British Columbia' => 'BC',
    'Manitoba' => 'MB',
    'New Brunswick' => 'NB',
    'Newfoundland and Labrador' => 'NL',
    'Northwest Territories' => 'NT',
    'Nova Scotia' => 'NS',
    'Nunavut' => 'NU',
    'Ontario' => 'ON',
    'Prince Edward Island' => 'PE',
    'Quebec' => 'QC',
    'Saskatchewan' => 'SK',
    'Yukon' => 'YT'
  }

  # When Slug.normalize just isn't good enough...
  def self.normalize_slug(text)
    _normalized = text.gsub(/[^a-zA-Z0-9_\- ]/,'') # Strip out non-alpha-numeric characters
    _normalized = Slug.normalize(_normalized)     # Let Slug take care of some other stuff
    _normalized.gsub!('-','_')                    # Override slug's - with _
    _normalized.gsub!(/[_]+/,'_')                 # Ensure that we have no __'s
    _normalized.gsub!(/\/+/,'/')                  # Remove extra trailing slashes
    _normalized
  end

  def self.canonical_url(url)
    (url + '/').gsub(/\/\/$/,'/')
  end

  def self.state_name_for(abbreviation)
    STATE_CODES.find{|k,v| v == abbreviation.to_s.upcase}[0] || nil
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

module ActiveRecord::Validations::ClassMethods
  # Overrides validates associates.
  # We do this to allow more better error messages to bubble up from associated models.
  # Adapted from thread at http://pivotallabs.com/users/nick/blog/articles/359-alias-method-chain-validates-associated-informative-error-message
  def validates_associated(*associations)
    # These configuration lines are required if your going to use any conditionals with the validates
    # associated - Rails 2.2.2 safe!
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
  include Utility

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
          _field.to_s =~ /_id$|\?$/ ? _int_terms[_field.to_s.gsub('?', '')] = pairs[_field] : _text_terms[_field] = pairs[_field]
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
    self.all.map{ |_x| [_x.name, _x.id] }
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

  def options_for_array( a, selected = nil )
    SELECT_PROMPT_OPTION + a.map{ |_e| _flag = _e[0].to_s == selected ? 'selected="1"' : ''; _e.is_a?(Array) ? "<option value=\"#{_e[0]}\" #{_flag}>#{_e[1]}</option>" : "<option>#{_e}</option>" }.to_s
  end

  def models_for_select( models, label = 'name' )
    models.map{ |m| [m[label], m.id] }.sort_by{ |e| e[0] }
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
  def sort_link(model, field, params)
    if (field.to_sym == params[:by] || field == params[:by]) && params[:dir] == "ASC"
      classname = "arrow-asc"
      dir = "DESC"
    elsif (field.to_sym == params[:by] || field == params[:by])
      classname = "arrow-desc"
      dir = "ASC"
    else
      dir = "DESC"
    end

    options = {
      :by => field,
      :dir => dir,
      :query => params[:query],
      :show_all => params[:show_all]
    }

    options[:show] = params[:show] unless params[:show].blank? || params[:show] == 'all'

    html_options = {
      :class => classname,
      :style => "color: white; font-weight: #{params[:by] == field ? "bold" : "normal"}",
      :title => "Sort by this field",
    }

    field_name = params[:labels] && params[:labels][field] ? params[:labels][field] : field.titleize

    _link = model.is_a?(Symbol) ? eval("#{model}_url(options)") : "/#{model}?#{options.to_params}"
    link_to(field_name, _link, html_options)
  end
end

class Array
  def mean
    self.inject(0){ |sum, x| sum += x } / self.size.to_f
  end
end

# From Ruby Cookbook
module Enumerable
  def to_histogram
    inject(Hash.new(0)) { |h,x| h[x] += 1; h }
  end
end

class Fixnum
  include Utility

  # Given a number of seconds, convert into a string like HH:MM:SS
  def to_hrs_mins_secs
    _now = DateTime.now
    _d = Date::day_fraction_to_time((_now + self.seconds) - _now)
    "#{sprintf('%02d',_d[0])}:#{sprintf('%02d',_d[1])}:#{sprintf('%02d',_d[2])}"
  end
end

class Float
  include Utility
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

 def self.from_array(array = [])
  h = Hash.new
  array.size.times do |t|
   h[t] = array[t]
  end
  h
 end

  def to_sql( operator = 'AND' )
    _sql = self.keys.map do |_key|
      _value = self[_key].is_a?(Fixnum) ? self[_key] : "'#{self[_key]}'"
      self[_key].nil? ? '1 = 1' : "#{_key} = #{_value}"
    end
    _sql * " #{operator} "
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
  include Utility::CoreExtensions::String::NumberHelper

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

  def has_http?
    !! (self =~ /^http[s]?:\/\//)
  end

  def has_trailing_slash?
    !! (self =~ /\/$/)
  end

  def is_page?
    !! (self =~ /\.htm[l]?$/)
  end
end

class StringHelperSingleton
  include Singleton
  include ActionView::Helpers::NumberHelper
end
