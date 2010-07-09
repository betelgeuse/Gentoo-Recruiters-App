require 'permissions/inherit.rb'
class QuestionContentMultipleChoice < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    content   :text
    timestamps
  end

  belongs_to  :question
  has_many    :options, :as => :option_owner, :accessible => true, :uniq => true


  def questions_permission(permission)
    if ['create', 'update'].include? permission.to_s
      question.send("#{permission.to_s.chop}able_by?", acting_user)
    else
      question.send("#{permission.to_s}able_by?", acting_user)
    end
  end

  one_permission(:view){ questions_permission(:view) }
  one_permission(:create){ questions_permission(:create) }
  one_permission(:update){ questions_permission(:update) }
  one_permission(:edit){ questions_permission(:edit) }
  one_permission(:destroy){ questions_permission(:destroy) }

  def new_answer_of(user)
    MultipleChoiceAnswer.new :question_id => question_id, :owner => user
  end
end
