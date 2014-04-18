require_relative 'sinatra_helpers'
require 'chartkick'
require 'active_support'

module Example
  class App < Sinatra::Base
    enable :sessions
    register Sinatra::Flash

    set :github_options, {
      :scopes    => ["repo, user"],
      :secret    => ENV['GITHUB_CLIENT_SECRET'],
      :client_id => ENV['GITHUB_CLIENT_ID'],
    }

    register Sinatra::Auth::Github
    

    helpers do

      def get_auth_info
        authInfo = {:username => github_user.login, :userID => github_user.id}
      end

      def flash_types
        [:danger, :warning, :info, :success]
      end
    end


    get '/' do
      # authenticate!
      if authenticated? == true
        @username = github_user.login
        @gravatar_id = github_user.gravatar_id
        @fullName = github_user.name
        @userID = github_user.id

      erb :index
     
      else
        erb :unauthenticated
      end

    end



    get '/download' do
      if authenticated? == true
        erb :download
      else
        # TODO: This needs work as it is not loading the message by the time the page loads.
        flash[:danger] = "You must be logged in"
        redirect '/'
        
      end 
    end


    get '/download/:user/:repo' do
      # authenticate!
      if authenticated? == true
        @username = github_user.login
        @userID = github_user.id

        Sinatra_Helpers.download_github_analytics_data(params['user'], params['repo'], github_api, get_auth_info )
        flash[:success] = "GitHub Data downloaded successfully"
        redirect '/download'
      else
        redirect '/download'
      end
    end


    get '/analyze/issues/:user/:repo' do
      # authenticate!
      if authenticated? == true

        @issuesOpenedPerUser = Sinatra_Helpers.analyze_issues_opened_per_user(params['user'], params['repo'], get_auth_info )
        @issuesOpenedPerUserChartReady ={}


        @issuesOpenedPerUser.each do |i|
          @issuesOpenedPerUserChartReady[i["user"]] = i["issues_opened_count"]
        end

        # flash[:success] = "GitHub Data downloaded successfully"
        # redirect '/download'
      
        erb :analyze_issues_opened_per_user
      else
        redirect '/'
      end
    end

    get '/analyze/issues/statetimeline/:user/:repo' do
      # authenticate!
      if authenticated? == true

        @issuesOpenedPerMonth = Sinatra_Helpers.analyze_issues_opened_per_month(params['user'], params['repo'], get_auth_info )
        @issuesClosedPerMonth = Sinatra_Helpers.analyze_issues_closed_per_month(params['user'], params['repo'], get_auth_info )
        @issuesOpenedClosedPerMonthChartReady ={}

        oldestOpenDate = @issuesOpenedPerMonth.first["converted_date"]
        newsestOpenDate = @issuesOpenedPerMonth.last["converted_date"]
        currentOpenDateItterator = oldestOpenDate
        while currentOpenDateItterator != newsestOpenDate do
           @issuesOpenedPerMonth << {"count" => 0, "converted_date" => currentOpenDateItterator.next_month}
        end

        oldestClosedDate = @issuesClosedPerMonth.first["converted_date"]
        newsestClosedDate = @issuesClosedPerMonth.last["converted_date"]
        currentClosedDateItterator = oldestClosedDate
        while currentClosedDateItterator != newsestClosedDate do
           @issuesClosedPerMonth << {"count" => 0, "converted_date" => currentClosedDateItterator.next_month}
        end




        @issuesOpenedPerMonth.each do |i|
          @issuesOpenedPerMonthChartReady[i["date"]] = i["count"]
        end

        @issuesClosedPerMonth.each do |i|
          @issuesClosedPerMonthChartReady[i["date"]] = i["count"]
        end

        # flash[:success] = "GitHub Data downloaded successfully"
        # redirect '/download'
      
        erb :analyze_issues_opened_closed_per_month
      else
        redirect '/'
      end
    end

# <%= line_chart [
#   {name: "Series A", data: series_a},
#   {name: "Series B", data: series_b}
# ] %>



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