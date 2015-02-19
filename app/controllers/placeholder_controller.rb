class PlaceholderController < ActionController::Base
  include MultiverseInterface

  before_filter :authenticate_user!, except: [:index]

  def index
  end

  def new_booster
  end

  # Read and parse the Multiverse set list, then return JS to
  # set up the drop down.
  def setup_multiverse_sets
    @sets = multiverse_sets.sort_by(&:name)
    render layout: false
  end

  def generate_booster
    if params[:multiverse] == 'false'
      @booster = CardSet.find(params[:id]).generate_booster
    else
      data = JSON.parse(params[:multiverse_data])
      set = CardSet.where { name == data['name'] }.first || CardSet.create(name: data['name'],
                                                                            remote_dictionary: true,
                                                                            dictionary_location: data['uri'])
      @booster = set.generate_booster
    end
    respond_to do |format|
      format.js
      format.html { render :new_booster }
    end
  ensure
    @booster.andand.each(&:destroy)
  end
end