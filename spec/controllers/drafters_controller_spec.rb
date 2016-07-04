require 'rails_helper'

RSpec.describe DraftersController, type: :controller do
  let(:drafter) { FactoryGirl.build(:drafter) }

  describe "when not signed in" do
    describe "POST #create" do
      it "redirects to the login page" do
        post :create, drafter: {draft_id: drafter.draft.to_param, user_id: drafter.user.to_param}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe "DELETE #destroy" do
      it "redirects to the login page" do
        drafter.save
        delete :destroy, id: drafter.to_param
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "when signed in" do
    before(:each) do
      login_user drafter.user
    end

    describe "POST #create" do
      it "creates a new drafter for this user in the specified draft" do
        expect {
          post :create, drafter: {draft_id: drafter.draft.to_param}
        }.to change(Drafter, :count).by 1
      end

      it "redirects to the associated draft's page" do
        post :create, drafter: {draft_id: drafter.draft.to_param,}
        expect(response).to redirect_to(drafter.draft)
      end

      it "redirects to drafts index if no draft specified" do
        expect {
          post :create, drafter: {draft_id: nil}
        }.to_not change(Drafter, :count)
        expect(response).to redirect_to(drafts_path)
      end

      it "redirects to the associated draft's page if drafter for that user-draft pair exists" do
        drafter.save
        expect {
          post :create, drafter: {draft_id: drafter.draft.to_param}
        }.to_not change(Drafter, :count)
        expect(response).to redirect_to(drafter.draft)
      end
    end

    describe "DELETE #destroy" do
      before(:each) { drafter.save }

      it "destroys a drafter if it belongs to the current user"  do
        expect {
          delete :destroy, id: drafter.to_param
        }.to change(Drafter, :count).by -1
      end

      it "redirects to the drafts index" do
        delete :destroy, id: drafter.to_param
        expect(response).to redirect_to(drafts_path)
      end

      it "deletes nothing if no drafter specified" do
        expect {
          delete :destroy, id: (Drafter.last.andand.id || 0) + 1
          }.to_not change(Drafter, :count)
      end

      it "redirects to the drafts index if no drafter specified" do
        delete :destroy, id: (Drafter.last.andand.id || 0) + 1
        expect(response).to redirect_to(drafts_path)
      end

      it "deletes nothing if the specified drafter is not for the current user" do
        user_two = FactoryGirl.create(:user)
        user_two.confirm
        drafter.user = user_two
        drafter.save
        expect {
          delete :destroy, id: drafter.to_param
        }.to_not change(Drafter, :count)
      end

      it "redirects to the drafts index if the specified drafter is not for the current user" do
        user_two = FactoryGirl.create(:user)
        user_two.confirm
        drafter.user = user_two
        drafter.save
        delete :destroy, id: drafter.to_param
        expect(response).to redirect_to(drafts_path)
      end
    end
  end
end
