require 'spec_helper'

describe "Cashier" do
  subject { Cashier }
  
  let(:cache) { Rails.cache }

  describe "#store_fragment" do
    it "should write the tag to the cache" do
      subject.store_fragment('fragment-key', 'dashboard')

      cache.fetch('dashboard').should eql(['fragment-key'])
    end

    it "should store the tag for book keeping" do
      subject.store_fragment('fragment-key', 'dashboard', 'settings')
      cache.fetch(Cashier::CACHE_KEY).should eql(%w(dashboard settings))
    end
  end

  describe "#expire" do
    before do
      subject.store_fragment('fragment-key', 'dashboard')
    end

    it "should remove delete the fragment key" do
      subject.expire('dashboard')
      Rails.cache.fetch('fragment-key').should be_nil
    end

    it "should remove the tag" do
      subject.expire('dashboard')
      Rails.cache.fetch('dashboard').should be_nil
    end

    it "should remove the tag from the list of tracked tags"  do
      subject.expire('dashboard')
      Rails.cache.fetch(Cashier::CACHE_KEY).should eql([])
    end
  end

  describe "#tags" do
    it "should return a list of active tags" do
      subject.store_fragment('key1', 'dashboard')
      subject.store_fragment('key2', 'settings')
      subject.store_fragment('key3', 'email')

      subject.tags.should eql(%w(dashboard settings email))
    end
  end

  describe '#clear' do
    before(:each) do
      subject.store_fragment('key1', 'dashboard')
      subject.store_fragment('key2', 'settings')
      subject.store_fragment('key3', 'email')
    end

    it "should expire all tags" do
      subject.should_receive(:expire).with('dashboard','settings','email')
      subject.clear
    end

    it "should clear the list of tracked tags" do
      subject.clear
      cache.fetch(Cashier::CACHE_KEY).should be_nil
    end
  end

  describe '#keys' do
    it "should return an array of all the tracked keys" do
      subject.store_fragment('key1', 'dashboard')
      subject.store_fragment('key2', 'settings')
      subject.store_fragment('key3', 'email')

      subject.keys.should eql(%w(key1 key2 key3))
    end
  end

  describe '#keys_for' do
    it "should return an array of all the keys for the tag" do
      subject.store_fragment('key1', 'dashboard')
      subject.store_fragment('key2', 'dashboard')
      subject.store_fragment('key3', 'dashboard')

      subject.keys_for('dashboard').should eql(%w(key1 key2 key3))
    end
  end
end
