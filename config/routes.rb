Rails.application.routes.draw do
  # Analytics routes
  get 'analytics', to: 'analytics#index'
  get 'analytics/performance'
  get 'analytics/conversion'
  get 'analytics/import_csv'
  post 'analytics/import_csv'
  get 'analytics/export_pdf'
  
  # Click Analytics routes
  get 'clicks_analytics', to: 'clicks_analytics#index'
  
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
    end
    resources :users do
      member do
        patch :change_role
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
