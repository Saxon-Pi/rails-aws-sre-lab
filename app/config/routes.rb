Rails.application.routes.draw do
  # hello -> HelloController, index -> def index
  get "/hello", to: "hello#index"
end
