require 'spec_helper'

describe Cashier::Adapters::RedisStore do
  subject { Cashier::Adapters::RedisStore }

  it "should allow to set the redis instance" do
    subject.respond_to?(:redis=).should be_true
  end

  it "should allow to get the redis instance" do
    subject.respond_to?(:redis).should be_true
  end

  it "should return the redis instance you set" do
    subject.redis = $redis
    subject.redis.should == $redis
  end

  
end