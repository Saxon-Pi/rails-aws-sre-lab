Rails.application.routes.draw do
  # hello -> HelloController, index -> def index
  get "/hello", to: "hello#index"

  get "/tasks", to: "tasks#index"
  get "/tasks/new", to: "tasks#new"
  post "/tasks", to: "tasks#create"
end
