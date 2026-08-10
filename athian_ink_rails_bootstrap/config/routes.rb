Rails.application.routes.draw do
  root "developer/dashboard#index"

  get "/agevidence", to: "agevidence/overview#show", as: :agevidence_root
  get "/agevidence/developer-os", to: "agevidence/developer_os#show", as: :agevidence_developer_os
  get "/campaign", to: "campaign/dashboard#show", as: :campaign_root
  get "/verifier", to: "verification_runs#new", as: :verifier_console

  get "/verify", to: "public_verifier#show", as: :public_verifier
  post "/verify", to: "public_verifier#create"
  get "/verify/lookup", to: "public_verifier#lookup_by_url", as: :public_verifier_lookup
  get "/verify/:id", to: "public_verifier#show", as: :public_verifier_result

  namespace :developer do
    resources :dashboard, only: [:index]
  end

  namespace :agevidence do
    resources :country_programs, only: [:index, :show] do
      post :evaluate, on: :member
    end
    resources :determinations, only: [:index, :show]
    resources :developer_accounts
    resources :developer_projects do
      resources :source_records, only: [:index, :create]
      resources :model_runs, only: [:new, :create]
      resources :pricing_quotes, only: [:new, :create, :show]
      resources :artifact_orders, only: [:create, :show] do
        post :checkout, on: :member
        post :assemble, on: :member
      end
      resources :artifact_engagements, only: [:index, :new, :create, :show]
    end
    resources :model_runs, only: [:show] do
      post :issue_receipt, on: :member
    end
    resources :evidence_candidates, only: [:show, :update]
    resources :evidence_gaps, only: [:show, :update]
    resources :review_decisions, only: [:create]
    resources :reliance_events, only: [:create]
    resource :revenue_model, only: [:show]
    get "developer-os/openapi", to: "developer_os#openapi", as: :developer_os_openapi
  end

  namespace :v1 do
    resources :country_adapters, only: [:index, :show], param: :id do
      post :validate, on: :member
      post :developer_determinations, on: :member
    end

    namespace :developer do
      resources :projects, only: [:create, :show] do
        resources :source_records, only: [:index, :create]
        resources :model_runs, only: [:create]
        resources :country_determinations, only: [:index, :create]
        resources :artifacts, only: [:create, :show] do
          get :download, on: :member
        end
      end
      resources :model_runs, only: [:show]
      resources :candidates, only: [:show, :update]
      resources :operations, only: [:show], param: :external_id
    end

    namespace :pricing do
      resources :products, only: [:index, :show], param: :code
      resources :quotes, only: [:create, :show], param: :external_id
    end

    resources :artifact_orders, only: [:create, :show], param: :external_id do
      post :checkout, on: :member
      post :assemble, on: :member
    end

    namespace :integrations do
      resources :events, only: [:create, :show], param: :external_event_id do
        post :replay, on: :member
      end
      resources :webhook_endpoints, only: [:index, :create, :destroy]
      resources :operations, only: [:show], param: :external_id
    end

    namespace :campaign do
      get "dashboard", to: "dashboard#show", as: :dashboard
      post "connectors/salesforce/events", to: "connectors/salesforce_events#create", as: :salesforce_events
      resources :accounts, only: [:index, :show, :create, :update] do
        resources :activations, only: [:index, :create], param: :external_id do
          post :complete, on: :member
          post :fail, on: :member
        end
      end
      resources :qualifications, only: [:create, :show]
      resources :activations, only: [:create, :show]
      resources :handoffs, only: [:create, :show]
    end
  end

  namespace :commercial do
    resources :orders
  end

  namespace :campaign do
    resources :accounts
    resources :dashboard
  end

  namespace :integrations do
    resources :events, only: [:index, :show] do
      post :replay, on: :member
    end
    resources :deliveries, only: [:index, :show] do
      post :retry, on: :member
    end
    resources :operations, only: [:index, :show]
    resources :outbox, only: [:index]
    resources :sources, only: [:index, :show]
    resources :dead_letter, only: [:index]
  end

  resources :avsas, only: [:show] do
    resource :co_claim_group, only: [:show, :update]
  end
  resources :projects
  resources :protocols, only: [:index, :show]
  resources :evidence_inbox, only: [:index]
  resources :gaps, only: [:index, :show]
  resources :reviews, only: [:index, :show]
  resources :country_programs do
    get :evaluate, on: :member
  end
  resources :receipts, only: [:show] do
    get :download, on: :member
    post :verify, on: :member
    resources :evidence_items, only: [:create]
  end
  resources :verification_runs, only: [:new, :create]
  resources :bundle_exports, only: [:index, :create]
  resources :producer_payments, only: [:index, :show]
  resources :methodology_migrations, only: [:index, :show, :create]
  resources :evidence_marketplace, only: [:index, :show]
  resources :dashboard, only: [:show]
  resources :evidence, only: [:index]
end
