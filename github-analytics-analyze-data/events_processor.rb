require_relative 'events_aggregation'
require_relative 'helpers'


module Events_Processor

    def self.analyze_repo_issues_Events_per_month(repo, githubAuthInfo)
      Events_Aggregation.controller
      repoIssueEventPerMonth = Events_Aggregation.get_repo_issues_Events_per_month(repo, githubAuthInfo)

      return repoIssueEventPerMonth
    end

end