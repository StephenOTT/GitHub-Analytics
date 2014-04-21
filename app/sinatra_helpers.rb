require_relative '../github-analytics-data-download/controller'
require_relative '../github-analytics-analyze-data/issues_processor'
require_relative '../github-analytics-analyze-data/labels_processor'
require_relative '../github-analytics-analyze-data/events_processor'
require_relative '../github-analytics-analyze-data/system_wide_processor'


module Sinatra_Helpers

    def self.get_all_repos_for_logged_user(githubAuthInfo)
      System_Wide_Processor.all_repos_for_logged_user(githubAuthInfo)
    end

    def self.download_github_analytics_data(user, repo, githubObject, githubAuthInfo)
		userRepo = "#{user}/#{repo}" 
		Analytics_Download_Controller.controller(userRepo, githubObject, true, githubAuthInfo)
    end

    def self.analyze_issues_opened_per_user(user, repo, githubAuthInfo)
		userRepo = "#{user}/#{repo}" 
		Issues_Processor.analyze_issues_opened_per_user(userRepo, githubAuthInfo)
    end

    def self.analyze_issues_opened_per_month(user, repo, githubAuthInfo)
		userRepo = "#{user}/#{repo}" 
		Issues_Processor.analyze_issues_opened_per_month(userRepo, githubAuthInfo)
    end

    def self.analyze_issues_closed_per_month(user, repo, githubAuthInfo)
		userRepo = "#{user}/#{repo}" 
		Issues_Processor.analyze_issues_closed_per_month(userRepo, githubAuthInfo)
    end

    def self.analyze_issues_opened_per_week(user, repo, githubAuthInfo)
        userRepo = "#{user}/#{repo}" 
        Issues_Processor.analyze_issues_opened_per_week(userRepo, githubAuthInfo)
    end

    def self.analyze_issues_closed_per_week(user, repo, githubAuthInfo)
        userRepo = "#{user}/#{repo}" 
        Issues_Processor.analyze_issues_closed_per_week(userRepo, githubAuthInfo)
    end

    def self.analyze_labels_count_per_repo(user, repo, githubAuthInfo)
        userRepo = "#{user}/#{repo}" 
        Labels_Processor.analyze_labels_count_for_repo(userRepo, githubAuthInfo)
    end


    def self.analyze_repo_issues_Events_per_month(user, repo, githubAuthInfo)
        userRepo = "#{user}/#{repo}" 
        Events_Processor.analyze_repo_issues_Events_per_month(userRepo, githubAuthInfo)
    end


end