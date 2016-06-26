class DraftsController < ApplicationController
  before_action :set_draft, only: [:show, :destroy]
  before_filter :authenticate_user!, except: [:index]

  respond_to :html

  def index
    @drafts = Draft.all
    respond_with(@drafts)
  end

  def show
    respond_with(@draft)
  end

  def new
    @draft = Draft.new
    respond_with(@draft)
  end

  def create
    @draft = Draft.new(draft_params)
    @draft.save
    respond_with(@draft)
  end

  def destroy
    @draft.destroy
    respond_with(@draft)
  end

  private
    def set_draft
      @draft = Draft.find(params[:id])
    end

    def draft_params
      params.require(:draft).permit(:name)
    end
end
