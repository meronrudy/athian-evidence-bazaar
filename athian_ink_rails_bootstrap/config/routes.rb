Rails.application.routes.draw do
  root "dashboard#show"

  resources :protocols, only: %i[index show]
  resources :evidence, only: :index, controller: "evidence"
  resources :evidence_marketplace, path: "marketplace", only: %i[index show]
  resources :methodology_migrations, only: %i[index show create]

  resources :avsas, only: :show do
    resource :co_claim_group, only: %i[show update]
  end

  resources :receipts, only: :show do
    member do
      get :download
      post :verify
    end
    resources :evidence_items, only: :create
  end

  get "verifier", to: "verification_runs#new", as: :verifier_console
  post "verifier", to: "verification_runs#create", as: :run_verification

  resources :producer_payments, only: %i[index show]
  resources :bundle_exports, only: %i[index create]

  namespace :agevidence do
    root "overview#show"

    resources :country_programs, only: %i[index show] do
      member do
        post :evaluate
      end
    end

    resources :developer_accounts
    resources :developer_projects do
      resources :model_runs, only: %i[new create]
      resources :artifact_engagements, only: %i[index new create show]
    end

    resources :model_runs, only: :show do
      member do
        post :issue_receipt
      end
    end

    resources :evidence_candidates, only: %i[show update]
    resources :evidence_gaps, only: %i[show update]
    resources :review_decisions, only: :create
    resources :reliance_events, only: :create

    resource :revenue_model, only: :show
  end
end
