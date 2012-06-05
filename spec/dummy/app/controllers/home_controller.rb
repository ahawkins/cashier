class HomeController < ApplicationController
  caches_action :index, :tag => Proc.new() { ["goober", "trooper"] }

  def index

  end
end
