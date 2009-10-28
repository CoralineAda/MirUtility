require File.dirname(__FILE__) + '/../spec_helper'
require 'singleton'

include MirUtility

describe MirUtility do

  it 'formats phone numbers' do
    ''.number_to_phone('5168675309').should == '516-867-5309'
  end

  it 'formats phone numbers with separate area codes' do
    '5168675309'.formatted_phone.should == '(516) 867-5309'
  end

  it 'handles invalid phone numbers gracefully' do
    'Alphabet Soup'.formatted_phone.should == 'Alphabet Soup'
    'Transylvania 6-5000'.formatted_phone.should == 'Transylvania 6-5000'
    '123-45-6789'.formatted_phone.should == '123-45-6789'
  end
  
  it 'formats zip codes' do
    '205000003'.formatted_zip.should == '20500-0003'
  end

  it 'calculates arithmetic means' do
    _a = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]
    _a.mean.should == (_a.sum.to_f/_a.size.to_f).to_f
  end

  it 'converts seconds to hours:minutes:seconds' do
    86400.to_hrs_mins_secs.should == '24:00:00'
  end

  it 'rounds to the nearest tenth' do
    Math::PI.to_nearest_tenth.should == 3.1
  end

  it 'converts active records to an array of name-value pairs suitable for select tags' do
    _control = User.all.map{ |_u| [_u.name, _u.id ] }
    User.to_option_values.should == _control
  end

  it 'converts arrays to a histogram hash' do
    [:r, :r, :o, :y, :g, :b, :i, :v, :v, :o].to_histogram.should == {:o=>2, :g=>1, :v=>2, :r=>2, :i=>1, :y=>1, :b=>1}
  end

  it 'converts a hash to SQL conditions' do
    _hash = {
      :first_name => 'Quentin',
      :last_name => 'Tarantino'
    }
    _quentin = User.make(:first_name => 'Quentin', :last_name => 'Tarantino')
    User.find( :first, :conditions => _hash.to_sql ).should == _quentin
    # TODO: spec OR case
  end
  
  it 'initializes SOAP headers' do
    _control = {
      :tag => '',
      :value => ''
    }
    _header = Header.new( _control[:tag], _control[:value] )
    _header.on_simple_outbound.should == _control[:value]
  end

  it 'capitalizes words without omitting characters like titleize' do
    'vice-president of the united states of america'.capitalize_words.should == 'Vice-President Of The United States Of America'
  end

  it 'expands address abbreviations' do
    _control = {
      '1600 Pennsylvania Av' => '1600 Pennsylvania Avenue',
      '1600 Pennsylvania Av.' => '1600 Pennsylvania Avenue',
      '1600 Pennsylvania Ave' => '1600 Pennsylvania Avenue',
      '1600 Pennsylvania Ave.' => '1600 Pennsylvania Avenue',
      '77 Sunset Bl' => '77 Sunset Boulevard',
      '77 Sunset Bl.' => '77 Sunset Boulevard',
      '77 Sunset Bld' => '77 Sunset Boulevard',
      '77 Sunset Bld.' => '77 Sunset Boulevard',
      '77 Sunset Blv' => '77 Sunset Boulevard',
      '77 Sunset Blv.' => '77 Sunset Boulevard',
      '77 Sunset Blvd' => '77 Sunset Boulevard',
      '77 Sunset Blvd.' => '77 Sunset Boulevard',
      '10 Columbus Cr' => '10 Columbus Circle',
      '10 Columbus Cr.' => '10 Columbus Circle',
      '10 Lincoln Ctr Plz' => '10 Lincoln Center Plaza',
      '10 Lincoln Ctr. Plz.' => '10 Lincoln Center Plaza',
      '157 King Arthur Ct' => '157 King Arthur Court',
      '157 King Arthur Ct.' => '157 King Arthur Court',
      '157 King Arthur Crt' => '157 King Arthur Court',
      '157 King Arthur Crt.' => '157 King Arthur Court',
      '680 N Lake Shore Dr' => '680 North Lake Shore Drive',
      '680 N. Lake Shore Dr.' => '680 North Lake Shore Drive',
      '8900 Van Wyck Expy' => '8900 Van Wyck Expressway',
      '8900 Van Wyck Expy.' => '8900 Van Wyck Expressway',
      '8900 Van Wyck Expw' => '8900 Van Wyck Expressway',
      '8900 Van Wyck Expw.' => '8900 Van Wyck Expressway',
      '8900 Van Wyck Expressw' => '8900 Van Wyck Expressway',
      '8900 Van Wyck Expressw.' => '8900 Van Wyck Expressway',
      '837 E Magical Frwy' => '837 East Magical Freeway',
      '837 E. Magical Frwy.' => '837 East Magical Freeway',
      '750 W Sunrise Hwy' => '750 West Sunrise Highway',
      '750 W. Sunrise Hwy.' => '750 West Sunrise Highway',
      '9264 Penny Ln' => '9264 Penny Lane',
      '9264 Penny Ln.' => '9264 Penny Lane',
      '10099 Ridge Gate Pky Ste 200' => '10099 Ridge Gate Parkway Suite 200',
      '10099 Ridge Gate Pky. Ste. 200' => '10099 Ridge Gate Parkway Suite 200',
      '10099 Ridge Gate Pkw Suite 200' => '10099 Ridge Gate Parkway Suite 200',
      '10099 Ridge Gate Pkw. Suite 200' => '10099 Ridge Gate Parkway Suite 200',
      '10099 Ridge Gate Pkwy Suite 200' => '10099 Ridge Gate Parkway Suite 200',
      '10099 Ridge Gate Pkwy. Suite 200' => '10099 Ridge Gate Parkway Suite 200',
      '10099 Ridge Gate Prkwy Suite 200' => '10099 Ridge Gate Parkway Suite 200',
      '10099 Ridge Gate Prkwy. Suite 200' => '10099 Ridge Gate Parkway Suite 200',
      "5137 Zebulon's Pk" => "5137 Zebulon's Pike",
      "5137 Zebulon's Pk." => "5137 Zebulon's Pike",
      "King's Plz" => "King's Plaza",
      "King's Plz." => "King's Plaza",
      '4616 Melrose Pl' => '4616 Melrose Place',
      '4616 Melrose Pl.' => '4616 Melrose Place',
      '93812 S Hightower Rd' => '93812 South Hightower Road',
      '93812 S. Hightower Rd.' => '93812 South Hightower Road',
      '249 NE Rural Rt' => '249 Northeast Rural Route',
      '249 N.E. Rural Rt.' => '249 Northeast Rural Route',
      '249 NE Rural Rte' => '249 Northeast Rural Route',
      '249 N.E. Rural Rte.' => '249 Northeast Rural Route',
      '1 SW Main St' => '1 Southwest Main Street',
      '1 S.W. Main St.' => '1 Southwest Main Street',
      '1935 SE Trpk' => '1935 Southeast Turnpike',
      '1935 S.E. Trpk.' => '1935 Southeast Turnpike',
      '369 NW Army Tr' => '369 Northwest Army Trail',
      '369 N.W. Army Tr.' => '369 Northwest Army Trail'
    }
    _control.keys.each do |_key|
      _key.expand_address_abbreviations.should == _control[_key]
    end
  end

  it 'converts 24-hour time' do
    '18:20'.to_12_hour_time == '6:20 PM'
  end

  it 'adds the HTTP-protocol prefix' do
    'www.seologic.com'.add_http_prefix.should == 'http://www.seologic.com'
    'ftp.seologic.com'.add_http_prefix.should == 'http://ftp.seologic.com'
    'ftp://ftp.seologic.com'.add_http_prefix.should == 'ftp://ftp.seologic.com'
  end

  it 'detects HTTP URLs' do
    'http://www.seologic.com/'.valid_http_url?.should be_true
    'https://www.seologic.com/'.valid_http_url?.should be_true
    'www.seologic.com'.valid_http_url?.should be_false
  end

  it 'detects trailing slashes' do
    'www.seologic.com'.has_http?.should be_false
    'www.seologic.com/'.has_trailing_slash?.should be_true
    'www.seologic.com/index'.has_trailing_slash?.should be_false
    'www.seologic.com/users/'.has_trailing_slash?.should be_true
  end

  it 'detects page URLs' do
    'www.seologic.com'.is_page?.should be_false
    'www.seologic.com/index'.is_page?.should be_false
    'www.seologic.com/index.cgi'.is_page?.should be_false
    'www.seologic.com/index.htm'.is_page?.should be_true
    'www.seologic.com/index.html'.is_page?.should be_true
  end

  it 'converts a URI string to a URI object' do
    'www.seologic.com'.to_uri.is_a?(URI).should be_true
    'http://www.seologic.com'.to_uri.is_a?(URI::HTTP).should be_true
  end

  it 'detects a valid HTTP URL' do
    'www.seologic.com'.valid_http_url?.should be_false
    'http://www.seologic.com'.valid_http_url?.should be_true
    lambda{ 'SEO Logic'.valid_http_url? }.should raise_error(ArgumentError)
  end

  it 'validates associated models with a meaningful message' do

    class Primary < ActiveRecord::Base
      has_many :secondaries
      validates_associated :secondaries
    end
    
    class Secondary < ActiveRecord::Base
      belongs_to :primary
      validate :name_should_not_be_illegal
      
      def name_should_not_be_illegal
        errors.add_to_base("Secondary's name cannot be illegal.") if self.name == 'illegal'
      end
    end
    
    container = Primary.new(:name => "My Folder")
    container.save.should be_true

    container.secondaries.create(:name => "legal").should be_true
    container.save.should be_true
    
    container.secondaries.create(:name => "illegal").should be_true
    container.save.should be_false
    
    container.errors.inspect.include?("Secondary's name cannot be illegal.").should be_true
    
  end
  
end
