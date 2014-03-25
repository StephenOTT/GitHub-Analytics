require_relative 'sinatra_helpers'

module Example
  class App < Sinatra::Base
    enable :sessions

    set :github_options, {
      :scopes    => "user",
      :secret    => ENV['GITHUB_CLIENT_SECRET'],
      :client_id => ENV['GITHUB_CLIENT_ID'],
    }

    register Sinatra::Auth::Github

    helpers do

      def get_auth_info
        authInfo = {:username => github_user.login, :userID => github_user.id}
      end

    end


    get '/' do
      # authenticate!
      if authenticated? == true
        @username = github_user.login
        @gravatar_id = github_user.gravatar_id
        @fullName = github_user.name
        @userID = github_user.id


      else
        # @dangerMessage = "Danger... Warning!  Warning"
        @warningMessage = "Please login to continue"
        # @infoMessage = "Info 123"
        # @successMessage = "Success"
      end
      erb :index
    end


    get '/logout' do
      logout!
      redirect '/'
    end
    get '/login' do
      authenticate!
      redirect '/'
    end
  end
end