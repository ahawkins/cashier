class HomeController < ApplicationController
  caches_action :index, :tag => 'cashier'

  def index

  end
end
