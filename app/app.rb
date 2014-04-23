require_relative 'sinatra_helpers'
require 'chartkick'

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

    get '/repos' do
      if authenticated? == true
        @reposList = Sinatra_Helpers.get_all_repos_for_logged_user(get_auth_info)
        erb :repos_listing
      else
        flash[:danger] = "You must be logged in"
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
      
        erb :analyze_issues_opened_per_user
      else
        redirect '/'
      end
    end

    get '/analyze/labels/:user/:repo' do
      # authenticate!
      if authenticated? == true

        @labelsCountForRepo = Sinatra_Helpers.analyze_labels_count_per_repo(params['user'], params['repo'], get_auth_info )
        @labelsCountForRepoChartReady ={}

        @labelsCountForRepo.each do |l|
          @labelsCountForRepoChartReady[l["label"]] = l["count"]
        end
      
        erb :analyze_labels_for_repo
      else
        redirect '/'
      end
    end


    get '/analyze/issues/events/:user/:repo' do
      # authenticate!
      if authenticated? == true

        @repoIssueEvents = Sinatra_Helpers.analyze_repo_issues_Events_per_month(params['user'], params['repo'], get_auth_info )
        # @repoIssueEventsChartReady ={}

        # @repoIssueEvents.each do |l|
        #   @repoIssueEventsChartReady[l["events"]] = l["count"]
        # end
      
        erb :analyze_repo_issue_events
      else
        redirect '/'
      end
    end







    get '/analyze/issues/statetimeline/:user/:repo' do
      # authenticate!
      if authenticated? == true

        @issuesOpenedPerMonth = Sinatra_Helpers.analyze_issues_opened_per_month(params['user'], params['repo'], get_auth_info)
        @issuesClosedPerMonth = Sinatra_Helpers.analyze_issues_closed_per_month(params['user'], params['repo'], get_auth_info)
        @issuesOpenedPerMonthChartReady ={}
        @issuesClosedPerMonthChartReady ={}

        @issuesOpenedPerMonth.each do |i|
          @issuesOpenedPerMonthChartReady[i["converted_date"].strftime("%b %Y")] = i["count"]
        end

        @issuesClosedPerMonth.each do |i|
          @issuesClosedPerMonthChartReady[i["converted_date"].strftime("%b %Y")] = i["count"]
        end



        @issuesOpenedPerWeek = Sinatra_Helpers.analyze_issues_opened_per_week(params['user'], params['repo'], get_auth_info)
        @issuesClosedPerWeek = Sinatra_Helpers.analyze_issues_closed_per_week(params['user'], params['repo'], get_auth_info)
        @issuesOpenedPerWeekChartReady ={}
        @issuesClosedPerWeekChartReady ={}

        @issuesOpenedPerWeek.each do |i|
          @issuesOpenedPerWeekChartReady["Week #{i["converted_date"].strftime("%U, %Y")}"] = i["count"]
        end

        @issuesClosedPerWeek.each do |i|
          @issuesClosedPerWeekChartReady["Week #{i["converted_date"].strftime("%U, %Y")}"] = i["count"]
        end




      
        erb :analyze_issues_opened_closed_per_month
      else
        redirect '/'
      end
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