Rails.application.routes.draw do
  devise_for :users

  root 'properties#index'
  resources :properties

  namespace :client do
    root 'dashboard#index'
    get 'dashboard', to: 'dashboard#index'
    resources :transactions, only: [:index, :show]
  end

  resources :business_transactions do
    patch :transfer_agent, on: :member
    resources :agent_transfers, only: [:create, :index]
  end

  namespace :admin do
    resources :property_types
    resources :operation_types
    resources :business_statuses
    resources :users
    resources :document_types
    resources :document_requirements
    resources :document_validity_rules
    resources :property_documents
  end

  namespace :superadmin do
    root 'base#index'
    resources :roles
    resources :menu_items
    get 'dashboard', to: 'base#index'
  end
end