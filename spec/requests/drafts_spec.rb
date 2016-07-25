require 'rails_helper'

RSpec.describe "Drafts", type: :request do
  it 'is linked from the homepage' do
    get '/'
    expect(response).to have_http_status(200)

    pending('not on placeholder controller')
    expect(response.body).to include('Create a draft')
  end

  context "when not signed in" do
    describe "GET #index" do
      it "renders the index" do
        get drafts_path

        expect(response.status).to eq 200
        expect(response).to render_template :index
      end
    end

    describe "GET #new" do
      it "redirects to the login page" do
        get new_draft_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe "GET #show" do
      it "redirects to the login page" do
        draft = FactoryGirl.create(:draft)
        get draft_path(draft)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe "POST #create" do
      it "redirects to the login page" do
        post drafts_path, {:draft => FactoryGirl.attributes_for(:draft)}

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'DELETE #destroy' do
      it "redirects to the login page" do
        draft = FactoryGirl.create(:draft)
        delete draft_path(draft)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context "when signed in" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      user.confirm
      login user
    end

    describe "GET #index" do
      it "renders the index" do
        get drafts_path

        expect(response.status).to eq 200
        expect(response).to render_template :index
      end
    end

    describe "GET #show" do
      it "renders the specified draft" do
        draft = FactoryGirl.create(:draft)
        get draft_path(draft)

        expect(response.status).to eq 200
        expect(response).to render_template :show
      end
    end

    describe "GET #new" do
      it "renders the creation form" do
        get new_draft_path
        expect(response.status).to eq 200
        expect(response).to render_template :new
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "redirects to the draft's edit page" do
          draft_attrs = FactoryGirl.attributes_for(:draft)
          post drafts_path, {:draft => draft_attrs}

          expect(response).to redirect_to(draft_path(Draft.last))
          follow_redirect!
          expect(response.body).to include(draft_attrs[:name])
        end

        it "assigns a newly created draft as @draft" do
          post drafts_path, {:draft => FactoryGirl.attributes_for(:draft)}
          expect(assigns(:draft)).to be_a(Draft)
          expect(assigns(:draft)).to be_persisted
        end

        it "redirects to the created draft" do
          post drafts_path, {:draft => FactoryGirl.attributes_for(:draft)}
          expect(response).to redirect_to(Draft.last)
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved draft as @draft" do
          post drafts_path, {:draft => FactoryGirl.attributes_for(:bad_draft)}
          expect(assigns(:draft)).to be_a_new(Draft)
        end

        it "re-renders the 'new' template" do
          post drafts_path, {:draft => FactoryGirl.attributes_for(:bad_draft)}
          expect(response).to render_template("new")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested draft" do
        draft = FactoryGirl.create(:draft)

        delete draft_path(draft)
        expect(response).to redirect_to(drafts_path)
      end
    end
  end

end
