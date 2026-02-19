Rails.application.routes.draw do
  devise_for :users

  namespace :client do
    root "dashboard#index"
    resources :transactions, only: [:index, :show]
  end

  resources :clients, only: [:index, :new, :create, :edit, :update, :show, :destroy] do
    collection do
      get :search
    end
  end

  root "properties#index"
  resources :properties
  
  resources :initial_contact_forms do
    member do
      post :convert_to_transaction
      get :edit_property_modal
      patch :update_property_from_modal
      post :update_property_from_modal  
      
      get :new_client_for_form     
      get :new_property_for_form   

      
      get :edit_client_modal
      patch :update_client_from_modal
      post :update_client_from_modal
      
      get :edit_co_owners_modal
      post :create_co_owner
    end
  end


  resources :business_transactions do
    patch :transfer_agent, on: :member
    post :export_documents, on: :member
    resources :agent_transfers, only: [:create, :index]
    resources :document_submissions, only: [:index, :show, :destroy] do
      # Acciones a nivel de documento (member)
      member do
        patch  :validate
        patch  :reject
        patch  :mark_expired
        post   :add_note
        delete :delete_note
        post   :preview
        get    :preview
        get    :download
        post   :upload
      end

      resources :notes, only:  [:destroy], controller: 'document_submission_notes'
      
      # Acciones a nivel de colección (no necesitan documento_submission ID)
      collection do
        get :export_checklist  # ← Export de TODA la colección
      end
    end
  end

  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    root to: 'dashboard#index' 
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