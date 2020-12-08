class UserAuthenticationController < ApplicationController
  # Uncomment this if you want to force users to sign in before any other actions
  # skip_before_action(:force_user_sign_in, { :only => [:sign_up_form, :create, :sign_in_form, :create_cookie] })

  def index
    matching_users = User.all

    @list_of_users = matching_users.order({ :created_at => :desc })

    render({ :template => "users/index.html.erb" })
  end

  def show
    the_username = params.fetch("path_username")

    if !@current_user
      redirect_to("/user_sign_in", { :alert => "You have to sign in first"})
      return
    end

    matching_users = User.where({ :username => the_username })

    @the_user = matching_users.at(0)
    followrequests = FollowRequest.where( :recipient_id => @the_user.id, :status => "accepted")
    @follower_count = followrequests.length
    followrequests = FollowRequest.where( :sender_id => @the_user.id, :status => "accepted")
    @following_count = followrequests.length
    @pending = FollowRequest.where( :recipient_id => @the_user.id, :status => "pending")
    @user_photos = Photo.where( :owner_id => @the_user.id)

    render({ :template => "users/show.html.erb" })
  end

  def liked
    the_username = params.fetch("path_username")

    matching_users = User.where({ :username => the_username })

    @the_user = matching_users.at(0)
    followrequests = FollowRequest.where( :recipient_id => @the_user.id, :status => "accepted")
    @follower_count = followrequests.length
    followrequests = FollowRequest.where( :sender_id => @the_user.id, :status => "accepted")
    @following_count = followrequests.length
    @liked_photos = []
    likes = Like.where( :fan_id => @the_user.id)
    likes.each do |like|
      @liked_photos += Photo.where( :id => like.photo_id)
    end

    render({ :template => "users/liked.html.erb" })
  end

  def feed
    the_username = params.fetch("path_username")

    matching_users = User.where({ :username => the_username })

    @the_user = matching_users.at(0)
    followrequests = FollowRequest.where( :recipient_id => @the_user.id, :status => "accepted")
    @follower_count = followrequests.length
    followrequests = FollowRequest.where( :sender_id => @the_user.id, :status => "accepted")
    @following_count = followrequests.length

    following = []
    followrequests.each do |fr|
      following += User.where( :id => fr.recipient_id)
    end

    @following_photos = [] 
    following.each do |user|
      @following_photos += Photo.where( :owner_id => user.id)
    end

    render({ :template => "users/feed.html.erb" })
  end

  def discover
    the_username = params.fetch("path_username")

    matching_users = User.where({ :username => the_username })

    @the_user = matching_users.at(0)
    followerrequests = FollowRequest.where( :recipient_id => @the_user.id, :status => "accepted")
    @follower_count = followerrequests.length
    followrequests = FollowRequest.where( :sender_id => @the_user.id, :status => "accepted")
    @following_count = followrequests.length

    following = []
    followrequests.each do |fr|
      following += User.where( :id => fr.recipient_id)
    end

    @liked_photos = []
    following.each do |user|
      likes = Like.where( :fan_id => user.id)
      likes.each do |like|
        @liked_photos += Photo.where( :id => like.photo_id)
      end
    end

    render({ :template => "users/discover.html.erb" })
  end

  def sign_in_form
    render({ :template => "user_authentication/sign_in.html.erb" })
  end

  def create_cookie
    user = User.where({ :email => params.fetch("query_email") }).first
    
    the_supplied_password = params.fetch("query_password")
    
    if user != nil
      are_they_legit = user.authenticate(the_supplied_password)
    
      if are_they_legit == false
        redirect_to("/user_sign_in", { :alert => "Incorrect password." })
      else
        session[:user_id] = user.id
      
        redirect_to("/", { :notice => "Signed in successfully." })
      end
    else
      redirect_to("/user_sign_in", { :alert => "No user with that email address." })
    end
  end

  def destroy_cookies
    reset_session

    redirect_to("/", { :notice => "Signed out successfully." })
  end

  def sign_up_form
    render({ :template => "user_authentication/sign_up.html.erb" })
  end

  def create
    @user = User.new
    @user.email = params.fetch("query_email")
    @user.password = params.fetch("query_password")
    @user.password_confirmation = params.fetch("query_password_confirmation")
    @user.private = params.fetch("query_private", false)
    @user.username = params.fetch("query_username")

    save_status = @user.save

    if save_status == true
      session[:user_id] = @user.id
   
      redirect_to("/", { :notice => "User account created successfully."})
    else
      redirect_to("/", { :alert => @user.errors.full_messages.to_sentence })
    end
  end
    
  def edit_profile_form
    render({ :template => "user_authentication/edit_profile.html.erb" })
  end

  def update
    @user = @current_user
    @user.email = params.fetch("query_email", @user.email)
    @user.password = params.fetch("query_password", @user.password)
    @user.password_confirmation = params.fetch("query_password_confirmation", @user.password_confirmation)
    @user.private = params.fetch("query_private", false)
    @user.username = params.fetch("query_username", @user.username)
    
    if @user.valid?
      @user.save

      redirect_to("/users/"+@user.username, { :notice => "User account updated successfully."})
    else
      render({ :template => "user_authentication/edit_profile_with_errors.html.erb" , :alert => @user.errors.full_messages.to_sentence })
    end
  end

  def destroy
    @current_user.destroy
    reset_session
    
    redirect_to("/", { :notice => "User account cancelled" })
  end
 
end
