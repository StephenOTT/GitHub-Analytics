require 'octokit'
# require 'pp'
require 'json'


# Monkey Patch code to make Sawyer::Response allow me to access the Raw Body and not 
# the Hypermedia version which is not does play friendly with MongoDB as it is not 
# JSON and currently no code exists to convert to JSON
module Response
  attr_reader :response_body

  def initialize(agent, res, option = {})
    @response_body = res.body
    super
  end
end
# Prepend the module to override initialize
::Sawyer::Response.send :prepend, Response


module GitHub_Data

	def self.gh_sinatra_auth(ghUser)

		@ghClient = ghUser
		Octokit.auto_paginate = true
		return @ghClient

	end

	def self.gh_authenticate(username, password)
		@ghClient = Octokit::Client.new(
										:login => username.to_s, 
										:password => password.to_s, 
										:auto_paginate => true
										)
	end

	def self.get_Issues(repo)
		issueResultsOpen = @ghClient.list_issues(repo, {
			:state => :open
			})
		responseOpen = JSON.parse(@ghClient.last_response.response_body)
		
		issueResultsClosed = @ghClient.list_issues(repo, {
			:state => :closed
			})
		responseClosed = JSON.parse(@ghClient.last_response.response_body)


		return mergedIssues = responseOpen + responseClosed
	end

	# def self.get_Milestones(repo)
	# 	milestonesResultsOpen = @ghClient.list_milestones(repo, {
	# 		:state => :open
	# 		})
	# 	milestonesResultsClosed = @ghClient.list_milestones(repo, {
	# 		:state => :closed
	# 		})

	# 	return mergedMilestones = milestonesResultsOpen + milestonesResultsClosed
	# end

	def self.get_Issue_Comments(repo, issueNumber)
		issueComments = @ghClient.issue_comments(repo, issueNumber)
		responseComments = JSON.parse(@ghClient.last_response.response_body)
	end

	# def self.get_code_commits(repo)
	# 	repoCommits = @ghClient.commits(repo)
	# end

	# def self.get_commit_comments(repo, sha)
	# 	commitComments = @ghClient.commit_comments(repo, sha)
	# end
end


# cat = GitHub_Data.gh_authenticate("USERNAME", "PASSWORD")
# issues = GitHub_Data.get_Issues("StephenOTT/Test1")
# pp issues
