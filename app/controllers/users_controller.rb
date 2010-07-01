class UsersController < ApplicationController

  hobo_openid_user_controller

  auto_actions :all, :except => [ :index, :new, :create ]
  index_action :ready_recruits
  index_action :mentorless_recruits

  def ready_recruits
    hobo_index User.recruits_answered_all
  end

  def mentorless_recruits
    hobo_index  User.mentorless_recruits
  end
end
