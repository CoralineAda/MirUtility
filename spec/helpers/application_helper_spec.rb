require File.dirname(__FILE__) + '/../spec_helper'

include ApplicationHelper

describe ApplicationHelper do
  it 'detects its action' do
    _controller = Object.new
    _controller.stubs(:action_name).returns('index')
    self.stubs(:controller).returns(_controller)
    self.action?('index').should be_true
    self.action?('destroy').should be_false
    self.action?(/index|show/).should be_true
  end

  it 'returns a check-mark div' do
    self.checkmark.should == '<div class="checkmark"></div>'
  end

  it 'detects its action' do
    _controller = Object.new
    _controller.stubs(:controller_name).returns('home')
    self.stubs(:controller).returns(_controller)
    self.controller?('home').should be_true
    self.controller?('primary').should be_false
    self.controller?(/home|primary/).should be_true
  end
end
