# frozen_string_literal: true

require 'spec_helper'

describe 'Rails cache integration' do
  subject(:cache) { Rails.cache }

  let(:cashier) { Cashier }

  context 'write' do
    it 'writes to cashier when I call Rails.cache.write with tags' do
      cashier.should_receive(:store_fragment).with('foo', ['some_tag'])
      cache.write('foo', 'bar', tag: ['some_tag'])
    end

    it 'shuld not write to cashier when I call Rails.cache.write without tags' do
      cashier.should_not_receive(:store_fragment)
      cache.write('foo', 'bar')
    end

    it "does not fail when I don't pass in any options" do
      expect { cache.write('foo', 'bar', nil) }.not_to raise_error
    end
  end

  context 'fetch' do
    it 'writes to cashier when I call Rails.cache.fetch with tags' do
      cashier.should_receive(:store_fragment).with('foo', ['some_tag'])
      cache.fetch('foo', tag: ['some_tag']) { 'bar' }
    end

    it 'shuld not write to cashier when I call Rails.cache.fetch without tags' do
      cashier.should_not_receive(:store_fragment)
      cache.fetch('foo') { 'bar' }
    end
  end
end
