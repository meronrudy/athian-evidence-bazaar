Rails.application.routes.draw do
  root "dashboard#show"

  # Project system routes
  resources :projects, only: %i[index show], path: "projects"
  resources :evidence, only: :index, controller: "evidence", path: "projects/:project_id/evidence"
  resources :assessment, only: :index, controller: "assessment", path: "projects/:project_id/assessment"
  resources :review, only: :index, controller: "review", path: "projects/:project_id/review"
  resources :artifact, only: :index, controller: "artifact", path: "projects/:project_id/artifact"
  resources :activity, only: :index, controller: "activity", path: "projects/:project_id/activity"

  # Public verifier routes
  get '/verify', to: 'public_verifier#show'
  get '/verify/:id', to: 'public_verifier#show'
  post '/verify', to: 'public_verifier#create'
  get '/verify/lookup_by_url', to: 'public_verifier#lookup_by_url'

  # Existing routes remain...
  # (rest of routes from previous content)
end
