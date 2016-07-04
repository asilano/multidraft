class DraftersController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  def create
    drafter = current_user.drafters.find_or_create_by(drafter_params)

    if drafter.persisted?
      respond_with(drafter.draft)
    else
      redirect_to drafts_path
    end
  end

  def destroy
    drafter = current_user.drafters.find_by_id(params[:id])
    if drafter
      drafter.destroy
    end

    redirect_to drafts_path
  end

private
  def drafter_params
    params.require(:drafter).permit(:user_id, :draft_id)
  end
end
