require 'spec_helper'

describe Cashier::StoreAdapters do
  subject { Cashier::StoreAdapters }

  it "should allow me to set the keys adapter" do
    subject.respond_to?(:adapter=).should be_true
  end

  it "shold allow to get the adapter" do
    subject.respond_to?(:current_adapter).should be_true
  end
end