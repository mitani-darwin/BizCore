Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  devise_for :users, skip: [ :registrations ]

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
    root to: "portal#index", as: :authenticated_root
    resource :my_attendance, only: [ :show ], controller: "self_attendance" do
      post :clock_in
      patch :clock_out
    end
    # 従業員セルフ画面: 日報
    resources :my_daily_reports, only: [ :index, :new, :create, :show, :edit, :update, :destroy ], controller: "daily_reports"
    # 従業員セルフ画面: 有給申請
    resources :my_leave_requests, only: [ :index, :new, :create, :show ], controller: "leave_requests"
    # 従業員セルフ画面: 経費精算
    resources :my_expense_reports, only: [ :index, :new, :create, :show ], controller: "expense_reports"
  end



  namespace :admin do
    resource :authorization, only: [ :show, :update ], controller: "authorizations"
    resources :assignments, only: [ :index, :create ]
    resources :permissions, only: [ :index, :create, :update, :destroy ]
    resources :audit_logs, only: [ :index, :show ]
    resources :tenants, only: [ :index, :show, :edit, :update ]
    resources :roles, only: [ :index, :show, :new, :create, :edit, :update ]
    resources :users, only: [ :index, :show, :new, :create, :edit, :update ]
    resources :employees, only: [ :index, :show, :new, :create, :edit, :update ] do
      collection do
        get  :import
        post :import
        get  :import_template
      end
    end
    resources :work_shifts, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
      collection do
        get :grid
      end
    end
    resources :attendance_records, only: [ :index, :show, :new, :create, :edit, :update ] do
      collection do
        post :clock_in
        post :close_month
      end
      member do
        patch :clock_out
      end
    end
    resources :leave_requests, only: [ :index, :show, :new, :create, :edit, :update ] do
      member do
        patch :approve
        patch :reject
      end
    end
    resources :leave_balances, only: [ :index ]
    resources :payroll_runs, only: [ :index, :show ] do
      collection do
        post :generate
      end
      member do
        patch :confirm
        get :download_excel
        get :download_pdf
      end
    end
    resources :customers, only: [ :index, :show, :new, :create, :edit, :update ] do
      collection do
        get  :import
        post :import
        get  :import_template
      end
    end
    resources :customer_inquiries, only: [ :index, :show, :new, :create, :edit, :update ]
    resources :customer_opportunities, only: [ :index, :show, :new, :create, :edit, :update ]
    resources :customer_sales, only: [ :index ]
    resources :suppliers, only: [ :index, :show, :new, :create, :edit, :update ]
    resources :receivables, only: [ :index ]
    resources :payables, only: [ :index ]
    resources :collection_schedules, only: [ :index ]
    resources :payment_schedules, only: [ :index ]
    resources :products, only: [ :index, :show, :new, :create, :edit, :update ] do
      collection do
        get  :import
        post :import
        get  :import_template
      end
    end
    resources :warehouses, only: [ :index, :show, :new, :create, :edit, :update ]
    resources :stock_items, only: [ :index, :show, :new, :create, :edit, :update ]
    resources :stock_movements, only: [ :index, :show, :new, :create ]
    resources :stock_counts, only: [ :index, :new, :create ]
    resources :purchase_orders, only: [ :index, :show, :new, :create, :edit, :update ] do
      member do
        get :download_excel
        get :download_pdf
        patch :send_purchase_order
        patch :receive_items
      end
    end
    resources :purchase_receipts, only: [ :index, :show ] do
      member do
        get :download_excel
        get :download_pdf
      end
    end
    resources :purchase_adjustments, only: [ :index, :show, :create ]
    resources :purchase_bill_batches, only: [ :index, :show ] do
      member do
        patch :cancel
      end
    end
    resources :purchase_bills, only: [ :index, :show ] do
      member do
        get :download_excel
        get :download_pdf
        patch :cancel
        post :reissue
      end
      collection do
        post :issue_monthly
      end
    end
    resources :supplier_payments, only: [ :index, :show, :new, :create, :edit, :update ] do
      member do
        patch :reconcile
      end
    end
    resources :quotations, only: [ :index, :show, :new, :create, :edit, :update ] do
      member do
        get :download_excel
        get :download_pdf
        patch :send_quotation
        patch :accept_quotation
        post :create_order
      end
    end
    resources :orders, only: [ :index, :show, :new, :create, :edit, :update ] do
      member do
        get :download_excel
        get :download_pdf
        patch :send_order
        patch :accept_order
        patch :reserve_stock
        patch :issue_delivery
      end
    end
    resources :deliveries, only: [ :index, :show ] do
      member do
        get :download_excel
        get :download_pdf
      end
    end
    resources :billing_batches, only: [ :index, :show ] do
      member do
        patch :cancel
      end
    end
    resources :invoices, only: [ :index, :show ] do
      member do
        get :download_excel
        get :download_pdf
        patch :cancel
        post :reissue
      end
      collection do
        post :issue_monthly
      end
    end
    resources :payments, only: [ :index, :show, :new, :create, :edit, :update ] do
      member do
        patch :reconcile
      end
    end
    resources :document_templates, only: [ :index, :edit, :update ], param: :document_type
    # 現場管理
    resources :sites do
      member do
        patch :update_progress
      end
    end
    resources :daily_reports
    # 契約管理
    resources :contracts, only: [ :index, :show, :new, :create, :edit, :update ]
    # 経費精算
    resources :expense_reports, only: [ :index, :show, :new, :create, :edit, :update ] do
      member do
        patch :approve
        patch :reject
      end
    end
    root to: "dashboard#index"
  end
end
