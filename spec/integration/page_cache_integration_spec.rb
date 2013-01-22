require 'spec_helper'

describe "Page cache integration" do
  subject{ ActionController::Base }
  let(:cashier) { Cashier }

  it "should ensure that cache operations are instrumented" do
    ActiveSupport::Cache::Store.instrument.should be_true
  end

  context "write" do
    it "should write to cashier when I call cache_page with tags" do
      cashier.should_receive(:store_page_path).with("/page/path", ["some_tag"])
      subject.cashiered_page("/page/path", nil, ["some_tag"])
    end
  end

  context "expire" do

  end

end