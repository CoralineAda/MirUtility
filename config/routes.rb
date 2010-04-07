# NOTE: Before modifying this file, keep these guidelines in mind:
# 1. Add specific routes towards the top, as either named or RESTful routes. Do NOT use leading or trailing slashes.
# 2. Add general routes to the bottom, since they interfere with more specific routes.
# 3. Add named routes to the top section. Group them alphabetically by controller or under 'singletons' (if only one route exists).
# 4. Add RESTful routes alphabetically by model in the middle section.
ActionController::Routing::Routes.draw do |map|
  # ======================================= Named routes ===========================================

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Singletons
  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.

  # ====================================== RESTful routes ==========================================

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # ========================== Generalized routes: careful with precedence! ========================

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
