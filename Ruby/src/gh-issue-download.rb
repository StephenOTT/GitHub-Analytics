require 'octokit'
require 'json'
require 'mongo'
require 'gchart'
require 'date'

include Mongo


class IssueDownload

	def initialize (repository)
		
		@repository = repository
	
		# TODO work on better way to handle organization and repositories as vairables.
		@organization = "wet-boew"
		
		# MongoDB Database Connect
		@client = MongoClient.new('localhost', 27017)
		@db = @client['test']
		
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
		issueResults = @ghClient.list_issues (@repository.to_s)
		issueResults.to_a
		# puts issueResults
		puts "Got issues, Github raite limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return issueResults
	end
	

	# TODO preform DRY refactor for Mongodb insert
	def putIntoMongoCollIssues (mongoPayload)
		@coll.insert(mongoPayload)
		puts "Issues Added, Count added to Mongodb: " + @coll.count.to_s
	end

	def putIntoMongoCollRepoEvents (mongoPayload)
		@collRepoEvents.insert(mongoPayload)
		puts "Repo Events Added, Count added to Mongodb: " + @collRepoEvents.count.to_s
	end

	def putIntoMongoCollOrgMembers (mongoPayload)
		@collOrgMembers.insert(mongoPayload)
		puts "Org Members Added, Count added to Mongodb: " + @collOrgMembers.count.to_s
	end
	
	# find records in Mongodb that have a comments field value of 1 or higher
	# returns only the number field
	def findIssuesWithComments
		i = 0
		#find filter is based on: http://stackoverflow.com/a/10443659
		issuesWithComments = @coll.find({"comments" => {"$gt" => 0}}, {:fields => {"_id" => 0, "number" => 1}}).to_a
		
		# Cycle through each issue number that was found in the mongodb collection and look up the comments related to that issue and update the issue mongodb document with the comments as a array
		issuesWithComments.each do |x|
 			puts x["number"]
 			issueComments = @ghClient.issue_comments(@repository.to_s, x["number"].to_s)
 			
 			# Updates comments_Text Created_at and updated_at fields  with proper time format for 
 			issueComments.each do |y|
 				y["created_at"] = DateTime.strptime(y["created_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
 				y["updated_at"] = DateTime.strptime(y["updated_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
 			end
 			 
			@coll.update(
				{ "number" => x["number"]},
				{ "$push" => {"comments_Text" => issueComments}}
				)
			 

			 # Used as a count for number of issues with comments
			 i += 1

		end 
		 
		 puts "Updated all Issues with Comments Github raite limit remaining: " + @ghClient.ratelimit_remaining.to_s
		 puts "Github issues with comments: " + i.to_s		

	end

	def getRepositoryEvents
		respositoryEvents = @ghClient.repository_events (@repository.to_s)
		puts "Got Repository Events, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return respositoryEvents
	end

	# TODO This still needs work to function correctly.  Need to add new collection in db and a way to handle variable for the specific org to get data from
	def getOrgMemberList
		orgMemberList = @ghClient.organization_members (@organization.to_s)
		puts "Got Organization member list, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgMemberList
	end
	
	def getOrgTeamsList
		orgTeamsList = @ghClient.organization_teams (@organization.to_s)
		puts "Got Organization Teams list, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgTeamsList
	end

	def getOrgTeamInfo (teamId)
		orgTeamInfo = @ghClient.team (teamId)
		puts "Got Team info for Team: #{teamId}, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgMemberList
	end

	def getOrgTeamMembers (teamId)
		orgTeamMembers = @ghClient.team_members (teamId)
		puts "Got members list of team: #{teamId}, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgTeamMembers
	end

	def getOrgTeamRepos (teamId)
		orgTeamRepos = @ghClient.team_repositories (teamId)
		puts "Got list of repos for team: #{teamId}, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgTeamRepos
	end

	# Sample method for showing the processing of data from coll and producing a Chart
	def analyzeEventsTypes
		
		# Query Mongodb and group event Types from RepoEvents collection and produce a count
		eventsTypesAnalysis = @collRepoEvents.aggregate([
			{"$group" => {_id: "$type", Count: {"$sum" => 1}}}
		])

		aValues=[]
		aLegends=[]

		# pass through each of the hases in the array eventsTypesAnalysis array and process then values into the new aValues and aLegends arrays
		eventsTypesAnalysis.each do |x|
			
			# generates a multidimensional array with each value in the eventsTypesAnalysis
			aValues.push([x["Count"]])

			# Produces a clean regular array with legend values based on the Type from the eventsTypesAnalysis query
			aLegends.push(x["_id"])
		end

		# For testing purposes
		puts aValues
		puts aLegends

		# Generates a URL from the Google charts api using the gchart gem
		chartURL = Gchart.bar(:title => "Event Types",
        	:data => aValues, 
        	#:bar_colors => 'FF0000,267678,FF0055,0800FF,00FF00',
        	:stacked => false, :size => '500x200',
        	:legend => aLegends)

		return chartURL
	end

	def convertDatesInMongo ()

			#fieldsToUpdate["created_at", "updated_at"]
			@coll.find.each do |x|
				createdAtDateTime = DateTime.strptime(x["created_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc
				updatedAtDateTime = DateTime.strptime(x["updated_at"], '%Y-%m-%dT%H:%M:%S%z').to_time.utc



				@coll.update(
					{"_id" => x["_id"] },
					{"$set" => {"created_at" => createdAtDateTime, "updated_at" => updatedAtDateTime}}
				)


		end
	end


end

#start = IssueDownload.new("wet-boew/wet-boew")
#start = IssueDownload.new("wet-boew/wet-boew-drupal")
start = IssueDownload.new("StephenOTT/Test1")
start.ghAuthenticate
start.putIntoMongoCollIssues(start.getIssues)
start.findIssuesWithComments
start.putIntoMongoCollRepoEvents(start.getRepositoryEvents)
start.putIntoMongoCollOrgMembers(start.getOrgMemberList)
puts start.analyzeEventsTypes
start.convertDatesInMongo
