require_relative 'issues_aggregation'
require_relative 'helpers'


module Issues_Processor

    def self.analyze_issues_opened_per_user(repo, githubAuthInfo)
      Issues_Aggregation.controller
      issuesOpenedPerUser = Issues_Aggregation.get_issues_opened_per_user(repo, githubAuthInfo)

      return issuesOpenedPerUser
    end

    def self.analyze_issues_opened_per_month(repo, githubAuthInfo)
      Issues_Aggregation.controller
      issuesOpenedPerMonth = Issues_Aggregation.get_issues_created_per_month(repo, githubAuthInfo)

      return issuesOpenedPerMonth
    end

    def self.analyze_issues_closed_per_month(repo, githubAuthInfo)
      Issues_Aggregation.controller
      issuesClosedPerMonth = Issues_Aggregation.get_issues_closed_per_month(repo, githubAuthInfo)

      return issuesClosedPerMonth
    end

    def self.analyze_issues_opened_per_week(repo, githubAuthInfo)
      Issues_Aggregation.controller
      issuesOpenedPerWeek = Issues_Aggregation.get_issues_created_per_week(repo, githubAuthInfo)

      return issuesOpenedPerWeek
    end

    def self.analyze_issues_closed_per_week(repo, githubAuthInfo)
      Issues_Aggregation.controller
      issuesClosedPerWeek = Issues_Aggregation.get_issues_closed_per_week(repo, githubAuthInfo)

      return issuesClosedPerWeek
    end



    # def self.process_issues_for_budget_left(issues)
    #   issues.each do |i|
    #     if i["budget_duration_sum"] != nil
    #       # TODO Cleanup code for Budget left.
    #       budgetLeftRaw = Helpers.budget_left?(i["budget_duration_sum"], i["time_duration_sum"])
    #       budgetLeftHuman = Helpers.convertSecondsToDurationFormat(budgetLeftRaw, "long")
    #       i["budget_left_raw"] = budgetLeftRaw
    #       i["budget_left_human"] = budgetLeftHuman
    #     end
    #   end
    #   return issues
    # end



    # def self.get_issues_in_milestone(user, repo, milestoneNumber, githubAuthInfo)
    #   userRepo = "#{user}/#{repo}"
    #   Issues_Aggregation.controller
    #   spentHours = Issues_Aggregation.get_all_issues_time_in_milestone(userRepo, milestoneNumber, githubAuthInfo)
    #   budgetHours = Issues_Aggregation.get_all_issues_budget_in_milestone(userRepo, milestoneNumber, githubAuthInfo)
    #   issues = Helpers.merge_issue_time_and_budget(spentHours, budgetHours)
    #   issues.each do |x|
    #     if x["time_duration_sum"] != nil
    #       x["time_duration_sum_human"] = Helpers.convertSecondsToDurationFormat(x["time_duration_sum"], "long")
    #     end
    #     if x["budget_duration_sum"] != nil
    #       x["budget_duration_sum_human"] = Helpers.convertSecondsToDurationFormat(x["budget_duration_sum"], "long")
    #     end
    #   end

    #   issues = self.process_issues_for_budget_left(issues)
    #   return issues

    # end


end