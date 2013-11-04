require 'octokit'
require 'mongo'
require 'gchart'
require 'date'
# require 'time_difference'
# require 'chartkick'
# require 'erb'
# require 'groupdate'
# require '../../../add_missing_dates_ruby/add_missing_dates_months.rb'
# require 'pp'
# require 'builder'

include Mongo


class IssueDownload

	def initialize (repository, clearRecords = false)
		
		@repository = repository
	
		# TODO work on better way to handle organization and repositories as vairables.
		@organization = "wet-boew"
		
		# MongoDB Database Connect
		@client = MongoClient.new('localhost', 27017)
		@db = @client['Github_WET']
		
		@coll = @db['githubIssues']
		

		@collRepoEvents = @db["githubRepoEvents"]
		@collRepoIssueEvents = @db["githubRepoIssueEvents"]
		@collOrgMembers = @db["githubOrgMembers"]
		@collRepoLabelsList = @db["githubRepoLabelsList"]
		@collRepoMilestonesList = @db["githubRepoMilestonesList"]
		
		# Debug code to empty out mongoDB records
		if clearRecords == true
			@coll.remove
			@collRepoEvents.remove
			@collRepoIssueEvents.remove
			@collOrgMembers.remove
			@collRepoLabelsList.remove
			@collRepoLabelsList.remove
		end
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

		if issueResultsOpen.empty? == false
			issueResultsOpen.each do |y|
				y["repo"] = @repository
				y["download_date"] = Time.now
			end
		elsif issueResultsClosed.empty? == false
			issueResultsClosed.each do |y|
				y["repo"] = @repository
				y["download_date"] = Time.now
			end
		end

		mergedIssuesOpenClose = issueResultsOpen + issueResultsClosed
		
		puts "Got issues, Github raite limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return self.convertIssueDatesInMongo(mergedIssuesOpenClose)
	end
	

	# TODO preform DRY refactor for Mongodb insert
	def putIntoMongoCollIssues(mongoPayload)
		@coll.insert(mongoPayload)
		# puts "Issues Added, Count in Mongodb: " + @coll.count.to_s
	end

	def putIntoMongoCollRepoEvents(mongoPayload)
		@collRepoEvents.insert(mongoPayload)
		# puts "Repo Events Added, Count in Mongodb: " + @collRepoEvents.count.to_s
	end

	def putIntoMongoCollOrgMembers(mongoPayload)
		@collOrgMembers.insert(mongoPayload)
		# puts "Org Members Added, Count in Mongodb: " + @collOrgMembers.count.to_s
	end

	def putIntoMongoCollRepoIssuesEvents(mongoPayload)
		@collRepoIssueEvents.insert(mongoPayload)
		# puts "Repo Issue Events Added, Count in Mongodb: " + @collRepoIssueEvents.count.to_s
	end

	def putIntoMongoCollRepoLabelsList(mongoPayload)
		@collRepoLabelsList.insert(mongoPayload)
		# puts "Repo Labels List Added, Count in Mongodb: " + @collRepoIssueEvents.count.to_s
	end

	def putIntoMongoCollRepoMilestonesList(mongoPayload)
		@collRepoMilestonesList.insert(mongoPayload)
		# puts "Repo Labels List Added, Count in Mongodb: " + @collRepoIssueEvents.count.to_s
	end
	
	# find records in Mongodb that have a comments field value of 1 or higher
	# returns only the number field
	# TODO  ***rebuild in option to not have to call MongoDB and add option to pull issues to get comments from directly from getIssues method
	def findIssuesWithComments
		i = 0
		#find filter is based on: http://stackoverflow.com/a/10443659
		issuesWithComments = @coll.find({"comments" => {"$gt" => 0}}, 
										{:fields => {"_id" => 0, "number" => 1}}
										).to_a
		
		# Cycle through each issue number that was found in the mongodb collection and look up the comments related to that issue and update the issue mongodb document with the comments as a array
		issuesWithComments.each do |x|
 			puts "x value:  #{x}"
 			puts x["number"]
 			issueComments = @ghClient.issue_comments(@repository.to_s, x["number"].to_s)

 			issueComments.each do |commentDetails| 			 
				@coll.update(
							{ "number" => x["number"]},
							{ "$push" => {"comments_Text" => self.convertIssueCommentDatesInMongo(commentDetails)}}
							)
			end
			 
			 # Used as a count for number of issues with comments
			 i += 1
		end 
		 
		 puts "Updated all Issues with Comments Github raite limit remaining: " + @ghClient.ratelimit_remaining.to_s
		 puts "Github issues with comments: " + i.to_s		
	end

	# TODO Setup so it will get all repo events since the last time a request was made
	def getRepositoryEvents
		respositoryEvents = @ghClient.repository_events(@repository.to_s)
		puts "Got Repository Events, GitHub rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		if respositoryEvents.empty? == false
			respositoryEvents.each do |y|
				y["repo"] = @repository
				y["download_date"] = Time.now
			end
			
			# self.putIntoMongoCollRepoIssuesEvents(issueEvents)
		end
		return self.convertRepoEventsDates(respositoryEvents)
	end

	# TODO Setup so will get issues events since the last time they were downloaded
	def getIssueEventsAllIssue

		issueNumbers = @coll.aggregate([
		    { "$project" => {number: 1}},
		    { "$group" => {_id: {number: "$number"}}},
		])

		issueNumbers.each do |x|
			issueEvents = @ghClient.issue_events(@repository, x["_id"]["number"])

			if issueEvents.empty? == false
				# Adds Repo and Issue number information into the hash of each event so multiple Repos can be stored in the same DB.
				# This was done becauase Issue Events do not have Issue number and Repo information.
				issueEvents.each do |y|
					y["repo"] = @repository
					y["issue_number"] = x["_id"]["number"]
				end
				# self.putIntoMongoCollRepoIssuesEvents(issueEvents)
				self.putIntoMongoCollRepoIssuesEvents(self.convertIssueEventsDates(issueEvents))
			end
			
		end
		puts "Got Repository Events, GitHub rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
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

			issueComments["created_at"] = DateTime.strptime(issueComments["created_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
			issueComments["updated_at"] = DateTime.strptime(issueComments["updated_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc

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

	def convertIssueEventsDates(issueEvents)
		issueEvents.each do |y|
			y["created_at"] = DateTime.strptime(y["created_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
		end
		return issueEvents
	end

	def getMilestonesListforRepo (repo)
		# TODO build call to github to get list of milestones in a specific issue queue.
		# This will be used as part of the web app to select a milestone and return specific details filtered for that specific milestone.
		# Second option for cases were no Github.com access is avaliable will be to query mongodb to get a list of milestones from mongodb data.  
		# This will be good for future needs when historical tracking is used to track changes in milestones or when milestone names are 
		# changed or even deleted.
	end

end



start = IssueDownload.new("CityofOttawa/Ottawa-ckan")
# start = IssueDownload.new("StephenOTT/Test1")
# start = IssueDownload.new("wet-boew/wet-boew-drupal")

start.ghAuthenticate
start.putIntoMongoCollIssues(start.getIssues)
start.findIssuesWithComments
# start.putIntoMongoCollRepoEvents(start.getRepositoryEvents)
# start.getIssueEventsAllIssue
# start.putIntoMongoCollOrgMembers(start.getOrgMemberList)
