Rails.application.routes.draw do
  devise_for :users
  root "home#index"
  resources :properties
  
  # ✅ RUTAS SUPERADMIN
  namespace :superadmin do
    # root 'dashboard#index'
    # root 'application#redirect_by_role'
    resources :menu_items do
      collection do
        patch :reorder
      end
    end

    resources :roles
  end
  
  namespace :admin do
    resources :document_types
    resources :document_requirements
    resources :document_validity_rules
    resources :property_documents, only: [:index, :show, :destroy]
    
    resources :users do
      member do
        patch :change_role
      end
    end
  end
  
  delete '/logout', to: 'devise/sessions#destroy', as: :logout
  resources :properties
  
  get "up" => "rails/health#show", as: :rails_health_check
end
