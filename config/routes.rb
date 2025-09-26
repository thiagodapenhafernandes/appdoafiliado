Rails.application.routes.draw do
  # Analytics routes
  get 'analytics/subid_cross_analysis', to: 'analytics#subid_cross_analysis', as: :subid_cross_analysis
  get 'analytics', to: 'analytics#index'
  get 'analytics/performance'
  get 'analytics/conversion'
  get 'analytics/import_csv'
  post 'analytics/import_csv'
  get 'analytics/export_pdf'
  patch 'analytics/update_ad_spend'
  delete 'analytics/destroy_commissions_by_period', to: 'analytics#destroy_commissions_by_period', as: :destroy_commissions_by_period
  delete 'analytics/destroy_all_commissions', to: 'analytics#destroy_all_commissions', as: :destroy_all_commissions
  
  # Click Analytics routes
  get 'clicks_analytics', to: 'clicks_analytics#index'
  get 'clicks_analytics/import_csv', to: 'clicks_analytics#import_csv'
  post 'clicks_analytics/import_csv', to: 'clicks_analytics#process_csv_upload'
  post 'clicks_analytics/persist_csv_to_db', to: 'clicks_analytics#persist_csv_to_db', as: :persist_clicks_csv_to_db
  get 'clicks_analytics/imports', to: 'clicks_analytics#imports', as: :clicks_analytics_imports
  delete 'clicks_analytics/delete_import/:id', to: 'clicks_analytics#delete_import', as: :delete_clicks_import
  delete 'clicks_analytics/destroy_by_period', to: 'clicks_analytics#destroy_by_period', as: :destroy_clicks_by_period
  delete 'clicks_analytics/destroy_all', to: 'clicks_analytics#destroy_all', as: :destroy_all_clicks
  
  # Devise routes
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Root route
  root 'home#index'

  # Dashboard
  get 'dashboard', to: 'dashboard#index'

  # Plans and Subscriptions
  resources :plans, only: [:index, :show]
  resources :subscriptions, only: [:new, :create, :show] do
    member do
      get 'payment'
    end
  end

  # Shopee Integration
  resource :shopee_integration, only: [:show, :new, :create, :edit, :update, :destroy] do
    member do
      post 'test_connection'
      post 'sync_now'
      post 'backfill'
      patch 'toggle_status'
    end
  end

  # Admin routes
  namespace :admin do
    resources :dashboard, only: [:index]
    resources :plans do
      member do
        patch :sync_with_stripe
      end
      collection do
        post :sync_from_stripe
      end
    end
    resources :users do
      collection do
        post :sync_all_stripe
      end
      member do
        patch :change_role
        post :sync_stripe
      end
    end
    resources :settings do
      collection do
        post :reset_defaults
      end
    end
    resources :stripe_config, only: [:index] do
      collection do
        post :sync_plans
        post :test_webhook
        patch :update_config
      end
    end
    resources :shopee_configs do
      member do
        post :test_connection
        patch :toggle_status
      end
    end
  end

  # Links management
  resources :links, except: [:create, :edit, :update, :destroy] do
    collection do
      post :create
      post :preview
    end
    member do
      get :edit
      patch :update
      delete :destroy
    end
  end

  # Link redirection - must be at the end to avoid conflicts
  get '/go/:short_code', to: 'redirect#show', as: :redirect_link

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Webhooks
  post '/webhooks/stripe', to: 'webhooks#stripe'
end
