class PlaceholderController < ActionController::Base
  layout "application"

  before_filter :authenticate_user!, except: [:index]

  def index
  end

  def new_booster
  end

  def generate_booster
    @booster = CardSet.find(params[:id]).generate_booster
    render
  ensure
    @booster.andand.each(&:destroy)
  end
end