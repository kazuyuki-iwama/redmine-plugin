# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
    resources :time_card
    post 'time_card/punchin'
    post 'time_card/punchout'
    post 'time_card/edit(.:format)' ,to: 'time_card#edit' ,as: 'time_card_edit'
    post 'time_card/edited(.:format)' ,to: 'time_card#edited' ,as: 'time_card_edited'
end