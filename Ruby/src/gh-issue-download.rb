require 'octokit'
require 'json'
require 'mongo'
require 'gchart'
require 'date'
require 'time_difference'
require 'sinatra'
require 'chartkick'
require 'erb'
require 'groupdate'
require '../../../add_missing_dates_ruby/add_missing_dates_months.rb'

include Mongo


class IssueDownload

	def initialize (repository)
		
		@repository = repository
	
		# TODO work on better way to handle organization and repositories as vairables.
		@organization = "wet-boew"
		
		# MongoDB Database Connect
		@client = MongoClient.new('localhost', 27017)
		@db = @client['Github']
		
		@coll = @db['githubIssues']
		@coll.remove

		@collRepoEvents = @db["githubRepoEvents"]
		@collRepoEvents.remove

		@collOrgMembers = @db["githubOrgMembers"]
		@collOrgMembers.remove
	end
	
	# TODO add authentication as a option for go live as Github Rate Limit is 60 hits per hour when unauthenticated by 5000 per hour when authenticated.
	# TODO PRIORITY username and password variables are not using "gets" correctly when used in terminal.  When in terminal after typing in credentials github api returns a bad credentials alert.  But when you type the credentials in directly in the code there is no issues.
	def ghAuthenticate ()
		#puts "Enter GitHub Username:"
		username = ""

		# TODO Add Highline gem support for Password no-Echo
		#puts "Enter GitHub Password:"
		password = ""
		@ghClient = Octokit::Client.new(:login => username.to_s, :password => password.to_s, :auto_traversal => true)		
	end
		
	def getIssues
				
		# TODO get list_issues working with options hash: Specifically need Open and Closed issued to be captured
		issueResultsOpen = @ghClient.list_issues(@repository.to_s, {
			:state => :open
			})

		issueResultsClosed = @ghClient.list_issues(@repository.to_s, {
			:state => :closed
			})


		mergedIssuesOpenClose = issueResultsOpen + issueResultsClosed
		

		puts "Got issues, Github raite limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return self.convertIssueDatesInMongo(mergedIssuesOpenClose)
	end
	

	# TODO preform DRY refactor for Mongodb insert
	def putIntoMongoCollIssues(mongoPayload)
		@coll.insert(mongoPayload)
		puts "Issues Added, Count added to Mongodb: " + @coll.count.to_s
	end

	def putIntoMongoCollRepoEvents(mongoPayload)
		@collRepoEvents.insert(mongoPayload)
		puts "Repo Events Added, Count added to Mongodb: " + @collRepoEvents.count.to_s
	end

	def putIntoMongoCollOrgMembers(mongoPayload)
		@collOrgMembers.insert(mongoPayload)
		puts "Org Members Added, Count added to Mongodb: " + @collOrgMembers.count.to_s
	end
	
	# find records in Mongodb that have a comments field value of 1 or higher
	# returns only the number field
	def findIssuesWithComments
		i = 0
		#find filter is based on: http://stackoverflow.com/a/10443659
		issuesWithComments = @coll.find({
			"comments" => {"$gt" => 0}}, 
				{:fields => {"_id" => 0, "number" => 1}}
				).to_a
		
		# Cycle through each issue number that was found in the mongodb collection and look up the comments related to that issue and update the issue mongodb document with the comments as a array
		issuesWithComments.each do |x|
 			puts x["number"]
 			issueComments = @ghClient.issue_comments(@repository.to_s, x["number"].to_s)
 			 			 
			@coll.update(
				{ "number" => x["number"]},
				{ "$push" => {"comments_Text" => self.convertIssueCommentDatesInMongo(issueComments)}}
				)
			 
			 # Used as a count for number of issues with comments
			 i += 1
		end 
		 
		 puts "Updated all Issues with Comments Github raite limit remaining: " + @ghClient.ratelimit_remaining.to_s
		 puts "Github issues with comments: " + i.to_s		
	end

	def getRepositoryEvents
		respositoryEvents = @ghClient.repository_events(@repository.to_s)
		puts "Got Repository Events, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		
		return self.convertRepoEventsDates(respositoryEvents)
	end

	# TODO This still needs work to function correctly.  Need to add new collection in db and a way to handle variable for the specific org to get data from
	def getOrgMemberList
		orgMemberList = @ghClient.organization_members(@organization.to_s)
		puts "Got Organization member list, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgMemberList
	end
	
	def getOrgTeamsList
		orgTeamsList = @ghClient.organization_teams(@organization.to_s)
		puts "Got Organization Teams list, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgTeamsList
	end

	def getOrgTeamInfo(teamId)
		orgTeamInfo = @ghClient.team(teamId)
		puts "Got Team info for Team: #{teamId}, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgMemberList
	end

	def getOrgTeamMembers(teamId)
		orgTeamMembers = @ghClient.team_members(teamId)
		puts "Got members list of team: #{teamId}, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgTeamMembers
	end

	def getOrgTeamRepos(teamId)
		orgTeamRepos = @ghClient.team_repositories(teamId)
		puts "Got list of repos for team: #{teamId}, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgTeamRepos
	end


	def convertIssueCommentDatesInMongo(issueComments)

		issueComments.each do |y|
			y["created_at"] = DateTime.strptime(y["created_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
			y["updated_at"] = DateTime.strptime(y["updated_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
		end
		return issueComments
	end

	def convertIssueDatesInMongo(issues)

		issues.each do |y|
			y["created_at"] = DateTime.strptime(y["created_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
			y["updated_at"] = DateTime.strptime(y["updated_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
			if y["closed_at"] != nil
				y["closed_at"] = DateTime.strptime(y["closed_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
			end
		end
		return issues
	end

	def convertRepoEventsDates(repoEvents)

		repoEvents.each do |y|
			y["created_at"] = DateTime.strptime(y["created_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
		end
		return repoEvents
	end

	def analyzeIssuesCreatedClosedCountPerMonth 
		
		return issuesCreatedPerMonth = @coll.aggregate([
		    { "$project" => {created_month: {"$month" => "$created_at"}, state: 1}},
		    { "$group" => {_id: {"created_month" => "$created_month", state: "$state"}, number: { "$sum" => 1 }}},
		    { "$sort" => {"_id.created_month" => 1}}
		])
	end

	def analyzeIssuesOpenClosedPerUserPerMonth
		
		return issuesOpenClosedPerUser = @coll.aggregate([
		    { "$project" => {created_month: {"$month" => "$created_at"}, state: 1, user:{login:1}}},
		    { "$group" => {_id: {user:"$user.login", "created_month" => "$created_month", state:"$state"}, number: { "$sum" => 1 }}},
		    { "$sort" => {"_id.user" => 1 ,"_id.created_month" => 1}}
		])
	end

	def analyzeIssuesClosedDurationOpen
		
		issuesOpenClosedPerUser = @coll.aggregate([
		    { "$match" => {state: "closed" }},
		    { "$project" => {state: 1, created_at: 1, closed_at: 1, user:{login:1}}},
		    { "$group" => {_id: {created_at:"$created_at",closed_at:"$closed_at", state:"$state", user:"$user.login"}}},
		    { "$sort" => {"_id.created_at" => 1}}
		])

		issuesOpenClosedPerUser.each do |y|
			durationDays = TimeDifference.between(y["_id"]["created_at"], y["_id"]["closed_at"]).in_days
			durationWeeks = TimeDifference.between(y["_id"]["created_at"], y["_id"]["closed_at"]).in_weeks
			durationMonths = TimeDifference.between(y["_id"]["created_at"], y["_id"]["closed_at"]).in_months
			y["_id"]["duration_open_days"] = durationDays
			y["_id"]["duration_open_weeks"] = durationWeeks
			y["_id"]["duration_open_months"] = durationMonths
		end

		return issuesOpenClosedPerUser
	end

	def analyzeIssuesAssignedCountPerUser
		
		return issuesAssignedCountPerUser = @coll.aggregate([
		    { "$project" => {assignee:{login: 1}, state: 1}},
		    { "$group" => {_id: {assignee:"$assignee.login", state:"$state"}, number: { "$sum" => 1 }}},
		    { "$sort" => {"_id.assignee" => 1 }}
		])
	end




end


#start = IssueDownload.new("CityofOttawa/Ottawa-ckan")
#start = IssueDownload.new("StephenOTT/Test1")
start = IssueDownload.new("wet-boew/wet-boew-drupal")
start.ghAuthenticate
start.putIntoMongoCollIssues(start.getIssues)
start.findIssuesWithComments
start.putIntoMongoCollRepoEvents(start.getRepositoryEvents)
start.putIntoMongoCollOrgMembers(start.getOrgMemberList)
#puts start.analyzeEventsTypes
puts start.analyzeIssuesCreatedClosedCountPerMonth
puts "************************"
puts start.analyzeIssuesOpenClosedPerUserPerMonth
puts "************************"
puts start.analyzeIssuesClosedDurationOpen
puts "************************"
puts start.analyzeIssuesAssignedCountPerUser