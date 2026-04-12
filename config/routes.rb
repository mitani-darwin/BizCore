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
    resources :customers, only: [:index, :show, :new, :create, :edit, :update]
    resources :suppliers, only: [:index, :show, :new, :create, :edit, :update]
    resources :receivables, only: [:index]
    resources :payables, only: [:index]
    resources :collection_schedules, only: [:index]
    resources :payment_schedules, only: [:index]
    resources :products, only: [:index, :show, :new, :create, :edit, :update]
    resources :warehouses, only: [:index, :show, :new, :create, :edit, :update]
    resources :stock_items, only: [:index, :show, :new, :create, :edit, :update]
    resources :stock_movements, only: [:index, :show, :new, :create]
    resources :stock_counts, only: [:index, :new, :create]
    resources :purchase_orders, only: [:index, :show, :new, :create, :edit, :update] do
      member do
        get :download_excel
        patch :send_purchase_order
        patch :receive_items
      end
    end
    resources :purchase_receipts, only: [:index, :show] do
      member do
        get :download_excel
      end
    end
    resources :purchase_adjustments, only: [:index, :show, :create]
    resources :purchase_bill_batches, only: [:index, :show] do
      member do
        patch :cancel
      end
    end
    resources :purchase_bills, only: [:index, :show] do
      member do
        get :download_excel
        patch :cancel
        post :reissue
      end
      collection do
        post :issue_monthly
      end
    end
    resources :supplier_payments, only: [:index, :show, :new, :create, :edit, :update] do
      member do
        patch :reconcile
      end
    end
    resources :quotations, only: [:index, :show, :new, :create, :edit, :update] do
      member do
        get :download_excel
        patch :send_quotation
        patch :accept_quotation
        post :create_order
      end
    end
    resources :orders, only: [:index, :show, :new, :create, :edit, :update] do
      member do
        get :download_excel
        patch :send_order
        patch :accept_order
        patch :reserve_stock
        patch :issue_delivery
      end
    end
    resources :deliveries, only: [:index, :show] do
      member do
        get :download_excel
      end
    end
    resources :billing_batches, only: [:index, :show] do
      member do
        patch :cancel
      end
    end
    resources :invoices, only: [:index, :show] do
      member do
        get :download_excel
        patch :cancel
        post :reissue
      end
      collection do
        post :issue_monthly
      end
    end
    resources :payments, only: [:index, :show, :new, :create, :edit, :update] do
      member do
        patch :reconcile
      end
    end
    root to: "dashboard#index"
  end
end
