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
		# Octokit.auto_paginate = true
		Octokit.per_page = 100
		return @ghClient

	end

	def self.gh_authenticate(username, password)
		@ghClient = Octokit::Client.new(
										:login => username.to_s, 
										:password => password.to_s, 
										# :auto_paginate => true
										:per_page => 100
										)
	end

	def self.get_Issues(repo)
		issueResultsOpen = @ghClient.list_issues(repo, {
			:state => :open,
			:per_page => 100
			})

		ghLastReponseOpen = @ghClient.last_response
		responseOpen = JSON.parse(@ghClient.last_response.response_body)
		
		while ghLastReponseOpen.rels.include?(:next) do
			ghLastReponseOpen = ghLastReponseOpen.rels[:next].get
			responseOpen.concat(JSON.parse(ghLastReponseOpen.response_body))
		end


		issueResultsClosed = @ghClient.list_issues(repo, {
			:state => :closed,
			:per_page => 100
			})

		ghLastReponseClosed = @ghClient.last_response
		responseClosed = JSON.parse(@ghClient.last_response.response_body)

		while ghLastReponseClosed.rels.include?(:next) do
			ghLastReponseClosed = ghLastReponseClosed.rels[:next].get
			responseClosed.concat(JSON.parse(ghLastReponseClosed.response_body))
		end

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
		issueComments = @ghClient.issue_comments(repo, issueNumber, {
			:per_page => 100
			})
		
		ghLastReponseComments = @ghClient.last_response

		responseComments = JSON.parse(@ghClient.last_response.response_body)
	
		while ghLastReponseComments.rels.include?(:next) do
			ghLastReponseComments = ghLastReponseComments.rels[:next].get
			responseComments.concat(JSON.parse(ghLastReponseComments.response_body))
		end
		
		return responseComments
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
