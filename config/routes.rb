Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root "dashboard#index"

  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "invitations/:token", to: "invitations#show", as: :show_invitation
  post "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation

  resources :organizations, only: [:show, :update] do
    member do
      post :switch
      patch :set_sendgrid_key
      delete :leave
    end

    resources :members, only: [:index, :destroy] do
      member do
        patch :promote_to_admin
      end
    end

    resources :invitations, only: [:new, :create]

    resources :contacts do
      collection do
        get :import
        post :process_import
        delete :bulk_destroy
      end
      member do
        post :add_tag
        delete :remove_tag
      end
    end
    resources :tags, except: [:show]
    resources :email_templates
    resources :campaigns do
      member do
        post :send_now
      end
    end
    resources :automation_rules
    get "analytics", to: "analytics#index"
  end
  post "webhooks/sendgrid", to: "webhooks#sendgrid"
  get "track/open/:campaign_send_id", to: "tracking#open", as: :track_open
  get "track/:campaign_send_id", to: "tracking#click", as: :track_click
  get "pages/home"

end
