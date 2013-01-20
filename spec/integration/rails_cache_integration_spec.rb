require "spec_helper"

describe "Rails cache integration" do
  subject { Rails.cache }
  let(:cashier) { Cashier }

  before(:each) do
    Cashier.adapter = :cache_store
  end

  it "should ensure that cache operations are instrumented" do
    ActiveSupport::Cache::Store.instrument.should be_true
  end

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

  context "read" do
    it "should keep track of fragment container hierarchy" do
      subject.fetch("foo1", :tag => ["some_tag", "some_other_tag"]) do
        subject.fetch("foo2", :tag => ["some_inner_tag", "some_other_inner_tag"]) { "bar" }
      end

      cashier.get_containers(["some_inner_tag"]).should == ["some_tag", "some_other_tag"]
      cashier.get_containers(["some_other_inner_tag"]).should == ["some_tag", "some_other_tag"]
    end
  end

  context "expire" do
    let(:notification_system) { ActiveSupport::Notifications }

    it "should expire containers when expiring a tag" do
      subject.fetch("foo3", :tag => ["outer_tag1", "outer_tag2"]) do
        subject.fetch("foo4", :tag => ["inner_tag1", "inner_tag2"]) { "bar" }
      end
      cashier.adapter.get_fragments_for_tag("outer_tag1").should == ["foo3"]

      cashier.expire("inner_tag1")
      cashier.adapter.get_fragments_for_tag("outer_tag1").should == []
    end
  end

end
