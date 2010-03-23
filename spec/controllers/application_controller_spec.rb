require File.dirname(__FILE__) + '/../spec_helper'

include MirUtility

describe ApplicationController do
  it 'sanitizes params' do
    controller.sanitize_params( 2, [1, 2, 3], 1).should == 2
    controller.sanitize_params( 0, [1, 2, 3], 1).should == 1
    controller.sanitize_params( nil, [1, 2, 3], 1).should == 1
    controller.sanitize_params( 0, nil, 1).should == 1
    lambda{ controller.sanitize_params( 0, [1, 2, 3], nil) }.should raise_error(ArgumentError)
    controller.sanitize_params( nil, nil, 1).should == 1
  end
end
