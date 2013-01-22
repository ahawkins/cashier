class HomeController < ApplicationController
  caches_action :index, :tag => Proc.new() { ["goober", "trooper"] }

  caches_page :show, :special, :nada
  cashier_pages :show, :tag => ["tag1", "tag2"]
  cashier_pages :special, :tag => Proc.new() { ["goober", "trooper"] }

  def index; end

  def show; end

  def special; end
  def nada; end
end
