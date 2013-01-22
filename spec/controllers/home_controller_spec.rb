require 'spec_helper'
require "rails"

describe HomeController do
  after :all do
    FileUtils.rm_rf HomeController.page_cache_directory + "/home"
    FileUtils.rm_rf HomeController.page_cache_directory + "/home.html"
  end

  def full_home_path(id)
    HomeController.page_cache_directory + home_path(id) +".html"
  end

  def home_path(id)
    "/home/#{id}"
  end

  describe "cashiered page" do
    after :each do
      FileUtils.rm_rf HomeController.page_cache_directory + "/home"
    end

    it "sets and after filter on actions with tags" do
      Cashier.adapter.get_page_paths_for_tag('tag1').should == []
      id = 1
      File.exists?(full_home_path(id)).should be_false
      get :show, id: id
      File.exists?(full_home_path(id)).should be_true
      Cashier.adapter.get_page_paths_for_tag('tag1').should == [home_path(id)]
    end

    describe "multiple pages" do
      it "should cache multiple pages under the same tag" do
        Cashier.adapter.get_page_paths_for_tag('tag1').should == []

        Cashier.store_page_path(home_path(1), ['tag1'])

        File.exists?(full_home_path(2)).should be_false
        get :show, id: 2
        File.exists?(full_home_path(2)).should be_true

        Cashier.adapter.get_page_paths_for_tag('tag1').should == [home_path(1), home_path(2)]
      end

      it "should handle multiple tags to same page" do
        Cashier.adapter.get_page_paths_for_tag('tag1').should == []
        Cashier.adapter.get_page_paths_for_tag('tag2').should == []

        File.exists?(full_home_path(2)).should be_false
        get :show, id: 2
        File.exists?(full_home_path(2)).should be_true

        Cashier.adapter.get_page_paths_for_tag('tag1').should == [home_path(2)]
        Cashier.adapter.get_page_paths_for_tag('tag2').should == [home_path(2)]
      end
    end
  end

  describe "proc" do
    it "should evaluate a proc" do
      path = home_path("special")
      Cashier.should_receive(:store_page_path).with(path, ["goober", "trooper"])
      get :special
    end

    it "should handle both page caching and fragment caching" do
      Cashier.adapter.get_page_paths_for_tag('goober').should == []
      Cashier.adapter.get_fragments_for_tag("goober").should == []

      get :special
      get :index

      Cashier.adapter.get_page_paths_for_tag('goober').should == [home_path("special")]
      Cashier.adapter.get_fragments_for_tag("goober").should == ["views/test.host/home"]
    end
  end

  describe "normal page cache" do
    it "should act normally" do
      Cashier.tags.should == []
      path = HomeController.page_cache_directory + "/home/nada.html"
      File.exists?(path).should be_false
      get :nada
      File.exists?(path).should be_true
      Cashier.tags.should == []
    end
  end

end