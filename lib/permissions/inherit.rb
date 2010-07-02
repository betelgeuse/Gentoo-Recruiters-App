require 'permissions/set.rb'
def inherit_permissions(source)
  for permission in AllPermissions - [:create]
    one_permission(permission){ send(source).send("#{permission.to_s}able_by?", acting_user)}
  end
  one_permission(:create){ send(source).send("creatable_by?", acting_user)}
end
