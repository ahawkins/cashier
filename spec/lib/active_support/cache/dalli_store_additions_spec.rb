require "spec_helper"

describe "DalliStoreAdditions" do
  subject { Rails.cache }
  let(:redis) { subject.redis }
  let(:cashier) { Cashier }

  context "write" do
    it "should write to cashier when I call Rails.cache.write with tags" do
      cashier.should_receive(:store_fragment).with("foo", ["some_tag"])
      subject.write("foo", "bar", :tag => ["some_tag"])
    end

    it "shuld not write to cashier when I call Rails.cache.write without tags" do
      cashier.should_not_receive(:store_fragment)
      subject.write("foo", "bar")
    end

    it "should not fail when I don't pass in any options" do
      expect { subject.write("foo", "bar", nil) }.to_not raise_error
    end
  end

  context "fetch" do
    it "should write to cashier when I call Rails.cache.fetch with tags" do
      cashier.should_receive(:store_fragment).with("foo", ["some_tag"])
      subject.fetch("foo", :tag => ["some_tag"]) { "bar" }
    end

    it "shuld not write to cashier when I call Rails.cache.fetch without tags" do
      cashier.should_not_receive(:store_fragment)
      subject.fetch("foo") { "bar" }
    end
  end
end