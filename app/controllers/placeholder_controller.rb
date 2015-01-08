class PlaceholderController < ActionController::Base
  layout "application"

  before_filter :authenticate_user!, except: [:index]

  def index
  end

  def new_booster
  end

  def generate_booster
    @booster = CardSet.find(params[:id]).generate_booster
    respond_to do |format|
      format.js
      format.html { render :new_booster }
    end
  ensure
    @booster.andand.each(&:destroy)
  end
end