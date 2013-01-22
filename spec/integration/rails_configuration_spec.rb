require 'spec_helper'

describe "Rails configuration" do
  it "should be configuration through rails" do
    Rails.application.config.cashier.adapter = :redis_store

    Cashier.adapter.should == Cashier::Adapters::RedisStore
  end
end
