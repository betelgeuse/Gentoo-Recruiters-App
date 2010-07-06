class Option < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    content :string
    timestamps
  end

  belongs_to    :option_owner, :polymorphic => true, :creator => true
  never_show    :option_owner_type
  one_permission(:view){option_owner.nil? || option_owner.send('viewable_by?', acting_user)}
  one_permission(:create){option_owner.nil? || option_owner.send('creatable_by?', acting_user)}
  one_permission(:update){option_owner.nil? || option_owner.send('updatable_by?', acting_user)}
  one_permission(:destroy){option_owner.nil? || option_owner.send('destroyable_by?', acting_user)}
  one_permission(:edit){option_owner.nil? || option_owner.send('editable_by?', acting_user)}

end
