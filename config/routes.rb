Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  devise_for :users, skip: [:registrations]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  devise_scope :user do
    unauthenticated do
      root to: "devise/sessions#new"
    end
  end
  
  # Defines the root path route ("/")
  authenticated :user do
    root to: "admin/dashboard#index", as: :authenticated_root
  end



  namespace :admin do
    resource :authorization, only: [:show, :update], controller: "authorizations"
    resources :permissions, only: [:index, :create, :update, :destroy]
    resources :audit_logs, only: [:index, :show]
    resources :tenants, only: [:index, :show, :edit, :update]
    resources :roles, only: [:index, :show, :new, :create, :edit, :update]
    resources :users, only: [:index, :show, :new, :create, :edit, :update]
    root to: "dashboard#index"
  end
end
