module Dates_Convert_For_MongoDB


def self.convertIssueCommentDatesInMongo(issueComments)
		issueComments["created_at"] = Time.strptime(issueComments["created_at"], '%Y-%m-%dT%H:%M:%S%z').utc
		issueComments["updated_at"] = Time.strptime(issueComments["updated_at"], '%Y-%m-%dT%H:%M:%S%z').utc
		return issueComments
	end

	def self.convertIssueDatesForMongo(issues)
		issues["created_at"] = Time.strptime(issues["created_at"], '%Y-%m-%dT%H:%M:%S%z').utc
		issues["updated_at"] = Time.strptime(issues["updated_at"], '%Y-%m-%dT%H:%M:%S%z').utc
		if issues["closed_at"] != nil
			issues["closed_at"] = Time.strptime(issues["closed_at"], '%Y-%m-%dT%H:%M:%S%z').utc
		end
		return issues
	end

	def self.convertRepoEventsDates(repoEvents)
		if repoEvents["created_at"] != nil
			repoEvents["created_at"] = Time.strptime(repoEvents["created_at"], '%Y-%m-%dT%H:%M:%S%z').utc
		end
		return repoEvents
	end

	def self.convertIssueEventsDates(issueEvents)
		if issueEvents["created_at"] != nil
			issueEvents["created_at"] = Time.strptime(issueEvents["created_at"], '%Y-%m-%dT%H:%M:%S%z').utc
		end
		return issueEvents
	end

	def self.convertMilestoneDates(milestone)
		milestone["created_at"] = Time.strptime(milestone["created_at"], '%Y-%m-%dT%H:%M:%S%z').utc
		milestone["updated_at"] = Time.strptime(milestone["updated_at"], '%Y-%m-%dT%H:%M:%S%z').utc
		if milestone["due_on"]!= nil
			milestone["due_on"] = Time.strptime(milestone["updated_at"], '%Y-%m-%dT%H:%M:%S%z').utc
		end
		return milestone
	end

	def self.convertTeamReposDates(teamRepos)
		teamRepos.each do |x|
			if x["created_at"] != nil
				x["created_at"] = Time.strptime(x["created_at"], '%Y-%m-%dT%H:%M:%S%z').utc
			end
			if x["updated_at"]!= nil
				x["updated_at"] = Time.strptime(x["updated_at"], '%Y-%m-%dT%H:%M:%S%z').utc
			end
			if x["pushed_at"] != nil
				x["pushed_at"] = Time.strptime(x["pushed_at"], '%Y-%m-%dT%H:%M:%S%z').utc
			end
		end
		return teamRepos
	end


end