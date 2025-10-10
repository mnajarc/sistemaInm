Rails.application.routes.draw do
  devise_for :users

  namespace :client do
    root "dashboard#index"
    resources :transactions, only: [:index, :show]
  end

  root "properties#index"
  resources :properties

  resources :business_transactions do
    patch :transfer_agent, on: :member
    resources :agent_transfers, only: [:create, :index]
  end

  namespace :admin do
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