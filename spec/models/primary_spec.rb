require File.dirname(__FILE__) + '/../spec_helper'

include MirUtility

describe Primary do
  it "returns SQL conditions suitable for use with ActiveRecord's finder" do
    _sql = Primary.search_conditions(Primary::SEARCH_CRITERIA, :id => 1)
    _sql.first.should == 'id = ?'
    _sql[1].should == 1

    _sql = Primary.search_conditions(Primary::SEARCH_CRITERIA, :name => 'Adam')
    _sql.first.should == 'name LIKE ?'
    _sql[1].should == "%Adam%"

    _sql = Primary.search_conditions([:name], :query => "Adam's rib")
    (_sql.first =~ /name LIKE ?/).should be_true
    (_sql.first =~ / OR /).should be_true
    _sql[1..2].include?("%Adam's%").should be_true
    _sql[1..2].include?("%rib%").should be_true

    _sql = Primary.search_conditions(Primary::SEARCH_CRITERIA, :id => 1, :name => 'Adam')
    (_sql.first =~ /id = ?/).should be_true
    (_sql.first =~ /name LIKE ?/).should be_true
    (_sql.first =~ / OR /).should be_true
    _sql[1..2].include?("%Adam%").should be_true
    _sql[1..2].include?(1).should be_true

    _sql = Primary.search_conditions(Primary::SEARCH_CRITERIA, :id => 1, :name => 'Adam', :query => 'Eve apple')
    (_sql.first =~ /id = ?/).should be_true
    (_sql.first =~ /name LIKE ?/).should be_true
    (_sql.first =~ / OR /).should be_true
    _sql[1..2].include?("%Adam%").should be_true
    _sql[1..2].include?(1).should be_true

    Primary.search_conditions([:name], :id => 1).should be_nil
  end
end
