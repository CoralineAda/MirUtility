require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationController do
  it 'detects its IP address' do
    ApplicationController.local_ip.should =~ /^192\.168\.[0-9]+\.[0-9]+$|^10\.[0-9]+\.[0-9]+\.[0-9]+$|^127.0.0.1$/
  end

  it 'sanitizes the sort-by param' do
    controller.stubs(:params).returns(:by => 'SELECT * FROM accounts')
    controller.sanitize_by_param.should == 'id'

    controller.stubs(:params).returns(:by => 'name')
    controller.sanitize_by_param(['name']).should == 'name'
  end

  it 'sanitizes the sort-direction param' do
    controller.stubs(:params).returns(:dir => 'DELETE FROM accounts')
    controller.sanitize_dir_param.should == 'ASC'

    controller.stubs(:params).returns(:dir => 'ASC')
    controller.sanitize_dir_param.should == 'ASC'

    controller.stubs(:params).returns(:dir => 'DESC')
    controller.sanitize_dir_param.should == 'DESC'
  end

  it 'sanitizes params' do
    controller.sanitize_params( 2, [1, 2, 3], 1).should == 2
    controller.sanitize_params( 0, [1, 2, 3], 1).should == '1'
    controller.sanitize_params( nil, [1, 2, 3], 1).should == '1'
    controller.sanitize_params( 0, nil, 1).should == '1'
    lambda{ controller.sanitize_params( 0, [1, 2, 3], nil) }.should raise_error(ArgumentError)
    controller.sanitize_params( nil, nil, 1).should == '1'
  end
end
