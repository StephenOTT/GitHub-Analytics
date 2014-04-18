require_relative '../github-analytics-data-download/controller'
require_relative '../github-analytics-analyze-data/issues_processor'
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

end