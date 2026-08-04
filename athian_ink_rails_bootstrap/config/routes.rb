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
end
