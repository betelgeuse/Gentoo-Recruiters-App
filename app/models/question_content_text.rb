require 'permissions/inherit.rb'
class QuestionContentText < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    content :text
    timestamps
  end

  belongs_to  :question

  inherit_permissions(:question)
end
