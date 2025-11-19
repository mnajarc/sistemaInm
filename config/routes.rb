Rails.application.routes.draw do
  devise_for :users

  namespace :client do
    root "dashboard#index"
    resources :transactions, only: [:index, :show]
  end
  
  resources :clients, only: [:index, :create, :show]

  root "properties#index"
  resources :properties
  
resources :initial_contact_forms do
  member do
    post :convert_to_transaction
  end
end



  resources :business_transactions do
    patch :transfer_agent, on: :member
    post :export_documents, on: :member  # ← NUEVA RUTA
    resources :agent_transfers, only: [:create, :index]
    resources :document_submissions, only: [:index, :show, :destroy] do
      member do
        get :preview
        post :upload
        post :validate_document
        post :reject_document
        get :download
      end
    end
  end

  namespace :admin do
    get 'instance-settings/edit', to: 'instance_settings#edit'
    patch 'instance-settings', to: 'instance_settings#update'
    resources :co_ownership_types
    resources :co_ownership_roles
    resources :property_types
    resources :operation_types
    resources :business_statuses
    resources :users
    resources :document_types
    resources :document_requirements
    resources :document_validity_rules
    resources :property_documents
    resources :business_transactions do
      resources :co_owners, controller: 'business_transaction_co_owners' do
        collection do
          post :auto_setup
        end
      end
    end
  end

  namespace :superadmin do
    root "base#index"
    resources :roles
    resources :menu_items
    get "dashboard", to: "base#index"
  end

  namespace :agent do
    # SIN ROOT - Los agentes usan el root global /properties
    resources :business_transactions, only: [:index, :show, :edit, :update] do
      resources :co_owners, controller: 'business_transaction_co_owners', except: [:destroy]
    end
  end
end