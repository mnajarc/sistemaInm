Rails.application.routes.draw do
  # get "home/index"
  devise_for :users
  root "home#index"
  
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
 
 # Ruta adicional GET para logout (más confiable)
  delete '/logout', to: 'devise/sessions#destroy', as: :logout

  resources :properties

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
