class UsersController < ApplicationController
  # protect_from_forgery except: [:create]

  def index
    @users = User.all
    # render html: index template
    render json: @users
  end

  def create
    @user = User.find_or_create_by(user_params)
    if @user.repositories.length == 0
      git_repos = check_repo_errors # this is the github fetch
      if git_repos.length == 0
        @user.destroy
        render json: []
      else
        @user.assign_repos(git_repos)
        render json: @user.repositories
      end
    elsif params[:refresh] == true
      @user.repositories.destroy_all
      git_repos = @user.find_repos
      @user.assign_repos(git_repos)
      render json: @user.repositories
    else
      render json: @user.repositories
    end
  end

  private

  def user_params
    params.require(:user).permit(:username)
  end

  def check_repo_errors
    begin
      git_repos = @user.find_repos # this is the github fetch
    rescue
      []
    end
  end
end
