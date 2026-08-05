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

  namespace :v1, defaults: { format: :json } do
    namespace :developer do
      resources :projects, only: %i[create show], param: :external_id do
        resources :source_records, only: %i[index create]
        resources :model_runs, only: %i[create show]
        resources :artifacts, only: %i[create show] do
          member do
            get :download
          end
        end
      end
      resources :candidates, only: %i[show update]
      resources :operations, only: :show, param: :external_id
    end

    namespace :pricing do
      resources :products, only: %i[index show], param: :code
      resources :quotes, only: %i[create show], param: :external_id
    end

    resources :artifact_orders, path: "artifact-orders", only: %i[create show], param: :external_id do
      member do
        post :checkout
      end
    end

    namespace :integrations do
      resources :events, only: %i[create show], param: :external_event_id do
        member do
          post :replay
        end
      end
      resources :operations, only: :show, param: :external_id
      resources :webhook_endpoints, only: %i[create index destroy]
    end
  end

  namespace :integrations do
    resources :sources, only: %i[index show]
    resources :events, only: %i[index show] do
      member do
        post :replay
      end
    end
    resources :operations, only: %i[index show]
    get "outbox", to: "outbox#index", as: :outbox
    resources :deliveries, only: %i[index show] do
      member do
        post :retry
      end
    end
    get "dead-letter", to: "dead_letter#index", as: :dead_letter
  end

  namespace :agevidence do
    root "overview#show"
    get "developer-os/openapi", to: "developer_os#openapi", as: :developer_os_openapi
    resource :developer_os, path: "developer-os", only: :show

    resources :country_programs, only: %i[index show] do
      member do
        post :evaluate
      end
    end

    resources :developer_accounts
    resources :developer_projects do
      resources :source_records, only: %i[index create]
      resources :pricing_quotes, only: %i[new create show]
      resources :artifact_orders, only: %i[create show] do
        member do
          post :checkout
          post :assemble
        end
      end
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
