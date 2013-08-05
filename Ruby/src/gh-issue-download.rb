require 'octokit'
require 'json'
require 'mongo'

include Mongo


class IssueDownload

	def initialize (repository)
		
		@repository = repository
		
		# TODO work on better way to handle organization and repositories as vairables.
		@organization = ""
		
		# MongoDB Database Connect
		@client = MongoClient.new('localhost', 27017)
		@db = @client['test']
		
		@coll = @db['githubIssues']
		@coll.remove


		@collRepoEvents = @db["githubRepoEvents"]
		@collRepoEvents.remove
		
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
		puts "Got issues, Github raite limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return issueResults
	end
	
	
	def putIntoMongoCollIssues (mongoPayload)
		@coll.insert(mongoPayload)
		puts "Issues Added, Count added to Mongodb: " + @coll.count.to_s
	end

	def putIntoMongoCollRepoEvents (mongoPayload)
		@collRepoEvents.insert(mongoPayload)
		puts "Repo Events Added, Count added to Mongodb: " + @collRepoEvents.count.to_s
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

	#TODO This still needs work to function correctly.  Need to add new collection in db and a way to handle variable for the specific org to get data from
	def getOrgMemberList
		orgMemberList = @ghClient.organization_members (@organization.to_s)
		puts "Got Organization member list, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		return orgMemberList
	end


end

#start = IssueDownload.new("wet-boew/wet-boew")
start = IssueDownload.new("wet-boew/wet-boew-drupal")
#start = IssueDownload.new("StephenOTT/Test1")
start.ghAuthenticate
start.putIntoMongoCollIssues(start.getIssues)
start.findIssuesWithComments
start.putIntoMongoCollRepoEvents(start.getRepositoryEvents)



