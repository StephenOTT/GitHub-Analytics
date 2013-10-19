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
require 'pp'
require 'builder'

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

		@collRepoIssueEvents = @db["githubRepoIssueEvents"]
		@collRepoIssueEvents.remove

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
				self.putIntoMongoCollRepoIssuesEvents(issueEvents)
			end
			# puts "Got Repository Events, Github rate limit remaining: " + @ghClient.ratelimit_remaining.to_s
		end

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

	def getMilestonesListforRepo (repo)
		# TODO build call to github to get list of milestones in a specific issue queue.
		# This will be used as part of the web app to select a milestone and return specific details filtered for that specific milestone.
		# Second option for cases were no Github.com access is avaliable will be to query mongodb to get a list of milestones from mongodb data.  
		# This will be good for future needs when historical tracking is used to track changes in milestones or when milestone names are 
		# changed or even deleted.
	end

end

class AnalyzeGHData

	def initialize
		
		# MongoDB Database Connect
		@client = MongoClient.new('localhost', 27017)
		@db = @client['Github']
		
		@coll = @db['githubIssues']

		@collRepoEvents = @db["githubRepoEvents"]

		@collOrgMembers = @db["githubOrgMembers"]
	end

	def analyzeIssuesCreatedClosedCountPerMonth 
		
		issuesCreatedPerMonth = @coll.aggregate([
			{ "$match" => {closed_at: {"$ne" => nil}}},
		    { "$project" => {created_month: {"$month" => "$created_at"}, created_year: {"$year" => "$created_at"}, closed_month: {"$month" => "$closed_at"}, closed_year: {"$year" => "$closed_at"}, state: 1}},
		    { "$group" => {_id: {"created_month" => "$created_month", "created_year" => "$created_year", state: "$state", "closed_month" => "$closed_month", "closed_year" => "$closed_year"}, number: { "$sum" => 1 }}},
		    #{ "$sort" => {"_id.created_month" => 1}}
		])

		issuesOpenCount = @coll.aggregate([
			{ "$match" => {state: {"$ne" => "closed"}}},
		    { "$project" => {state: 1}},
		    { "$group" => {_id: {state: "$state"}, number: { "$sum" => 1 }}},
		])

		newHashOpened={}
		newHashClosed={}
		issuesCreatedPerMonth.each do |x|
				newHashOpened[Date.strptime(x["_id"].values_at('created_month', 'created_year').join(" "), '%m %Y')] = x["number"]
			
			if x["_id"]["closed_month"] != nil
				newHashClosed[Date.strptime(x["_id"].values_at('closed_month', 'closed_year').join(" "), '%m %Y')] = x["number"]
			end
		end

		dateConvert = DateManipulate.new()

		return dateConvert.sortHashPlain(newHashOpened), dateConvert.sortHashPlain(newHashClosed), issuesOpenCount
	end

	# TODO Need to rebuild this as the Events data should be used rather than Issues data
	def analyzeIssuesOpenClosedPerUserPerMonth
		issuesOpenClosedPerUser = @coll.aggregate([
		    { "$project" => {created_month: {"$month" => "$created_at"}, created_year: {"$year" => "$created_at"}, state: 1, user:{login:1}}},
		    { "$group" => {_id: {user:"$user.login", "created_month" => "$created_month", "created_year" => "$created_year", state:"$state"}, number: { "$sum" => 1 }}},
		    { "$sort" => {"_id.user" => 1}}
		])
		# puts issuesOpenClosedPerUser

		usersBase = []
		issuesOpenClosedPerUser.each do |y|
			usersBase << y["_id"]["user"] 
		end
		usersBase.uniq!
		
		usersBase.each do |ub|
			issuesOpenClosedForUniqueUser = @coll.aggregate([
			    { "$project" => {created_month: {"$month" => "$created_at"}, created_year: {"$year" => "$created_at"}, state: 1, user:{login:1}}},
			    { "$match" => {user:{login:ub }}},
			    { "$group" => {_id: {user:"$user.login", "created_month" => "$created_month", "created_year" => "$created_year", state:"$state"}, number: { "$sum" => 1 }}},
			    # { "$sort" => {"_id.user" => 1}}
			])
			# puts issuesOpenClosedForUniqueUser
		end
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
			durationFull = TimeDifference.between(y["_id"]["created_at"], y["_id"]["closed_at"]).in_general
			y["_id"]["duration_open_full"] = durationFull
			y["_id"]["duration_open_days"] = durationDays
			y["_id"]["duration_open_weeks"] = durationWeeks
			y["_id"]["duration_open_months"] = durationMonths
		end

		return issuesOpenClosedPerUser
	end

	def analyzeIssuesAssignedCountPerUser (inlcudeUnassigned = true)
		# inlcudeUnassigned = true
		issuesAssignedCountPerUser = @coll.aggregate([
		    # { "$project" => {assignee:{login: 1}, state: 1}},
		    { "$group" => {_id: {assignee:{"$ifNull" => ["$assignee.login","Unassigned"]}, state:"$state"}, number: { "$sum" => 1 }}},
		    { "$sort" => {"_id.assignee" => 1 }}
		])

		openCountHash = {}
		closedCountHash = {}
		issuesAssignedCountPerUser.each do |x|
			# x["_id"]["number"] = x["number"]
			if inlcudeUnassigned == false and x["_id"]["assignee"] != "Unassigned"
					if x["_id"]["state"] == "open"
						openCountHash[x["_id"]["assignee"]] = x["number"]
					elsif x["_id"]["state"] == "closed"
						closedCountHash[x["_id"]["assignee"]] = x["number"]
					end
			elsif inlcudeUnassigned == true 
					if x["_id"]["state"] == "open"
						openCountHash[x["_id"]["assignee"]] = x["number"]
					
					elsif x["_id"]["state"] == "closed"
						closedCountHash[x["_id"]["assignee"]] = x["number"]
					end
			end 		
		end
		return openCountHash, closedCountHash


	end

	# Sample method for showing the processing of data from coll and producing a Chart
	def analyzeEventsTypes
		
		# Query Mongodb and group event Types from RepoEvents collection and produce a count
		eventsTypesAnalysis = @collRepoEvents.aggregate([
			{"$group" => { _id: "$type", count: {"$sum" => 1}}}
		])

		newHash={}
		eventsTypesAnalysis.each do |x|
			newHash[x["_id"]] = x["count"]
		end
		return newHash
	end

	def analyzeEvents_IssueCommmentEvent

		issuesOpenClosedForUniqueUser = @collRepoEvents.aggregate([
			# { "$project" => {payload:{action:1}, _id:1}},
			# { "$match" => {type:"IssuesEvent"}},
			{ "$group" => {_id: {"user" => "$actor.login","type" =>"$payload.action"}, number: { "$sum" => 1 }}},
			{ "$sort" => {"_id.user" => 1}}
		])
		puts issuesOpenClosedForUniqueUser
	end


	def analyzeIssuesPrintableTable
		issuesPrintableTable = @coll.aggregate([
		    # { "$project" => {assignee:{login: 1}, state: 1, milestone:{title: 1}, number: 1, title: 1, created_at: 1, closed_at: 1, _id: 0}},
		    { "$group" => {_id: {
								issueCurrentState:"$state", 
								issueNumber:"$number", 
								issueAssignedMilestone:"$milestone.title", 
								issueTitle:"$title", 
								issueCurrentAssignee:"$assignee.login", 
								created_at:"$created_at", 
								closed_at:"$closed_at", 
								createdBy:"$user.login", 
								createdByAvatar:"$user.avatar_url", 
								commentsCount:"$comments"}}},
		    { "$sort" => {"_id.issueCurrentState" => -1, "_id.issueNumber" => -1}}
		])
		printableArray = []
		issuesPrintableTable.each do |x|
			#gets comments and sparkline data for supplied issue number and the CURRENT year
			dog = self.issueCommentsDatesBreakdownWeek(x["_id"]["issueNumber"], Time.now.strftime('%Y').to_i)
			x["_id"]["sparkline"] = dog
			printableArray << x["_id"]
		end
		return printableArray
		# return buildSampleTable(printableArray)
	end

	# TODO add better support for sparklines/images in the table.  Currently images cannot be added because of the code.
	# TODO remove this method as it is not needed anymore.  Double check dependencies.
	def buildSampleTable (data)
		xm = Builder::XmlMarkup.new(:indent => 2)
		xm.table {
		  xm.tr { data[0].keys.each { |key| xm.th(key)}}
		  data.each { |row| xm.tr { row.values.each { |value| xm.td(value)}}}
		}
	end

	def issueCommentsDatesBreakdownWeek(issueNumber, yearSpan)

		issueCommentsDatesSpark = @coll.aggregate([
			{ "$match" => {number: issueNumber}},
		    { "$unwind" => "$comments_Text" },
			# { "$project" => {created_month: {"$month" => "$comments_Text.created_at"}, created_year: {"$year" => "$comments_Text.created_at"}}},
			{ "$project" => {created_week: {"$week" => "$comments_Text.created_at"}, created_year: {"$year" => "$comments_Text.created_at"}}},
			{ "$match" => {created_year: yearSpan}},
			# TODO write a blog post about dealing match and how $eq does not work correctly
			# { "$match" => {created_year: {"$gt" => yearSpan-1}}},
			# { "$match" => {created_year: {"$lt" => yearSpan+1}}},
			# { "$group" => {_id:{"created_month" => "$created_month", "created_year" => "$created_year"}, number: { "$sum" => 1 }}},
			{ "$group" => {_id:{"created_week" => "$created_week", "created_year" => "$created_year"}, number: { "$sum" => 1 }}},
		])

		newHash = {}
		issueCommentsDatesSpark.each do |x|
				# newHash[Date.strptime(x["_id"].values_at('created_week', 'created_year').join(" "), '%U %Y')] = x["number"]
				newHash[x["_id"]["created_week"]] = x["number"] 
		end

		# figures out missing week numbers and if the week number is missing creates it and assigns value as 0
		for i in 0..Time.now.strftime('%W').to_i    # gets week 0 to current week number of activity
			# If the week does not already exist in the hash then add a new hash value with the key being the week number and the value is 0 becuase there was not previous value
			if newHash.key?(i) == false
				newHash[i] = 0
			end
		end

		# TODO support for sparkline images in table builder is still required
		dateConvert = DateManipulate.new()
		sortedHash = dateConvert.simpleHashSort(newHash)
		return self.produceSparklineChart(sortedHash)
	end

	# TODO add support for custom sizes and colours when calling spark line generator
	def produceSparklineChart(data)
			return chartURL = Gchart.sparkline(
        	:data => data.values,
        	:size => '80x20'
        	)
	end

end


class MyApp < Sinatra::Base

  get '/' do

    @foo = 'erb23'
    analyze = AnalyzeGHData.new()
  	# @hourBreakdown = column_chart(analyze.analyzeRestaurantInspectionsCount("hour"))
  	# @weekBreakdown = column_chart(analyze.analyzeRestaurantInspectionsCount("week"))
  	# @monthBreakdown = column_chart(analyze.analyzeRestaurantInspectionsCount("month"))
  	# @dayOfWeekBreakdown = column_chart(analyze.analyzeRestaurantInspectionsCount("dayOfWeek"))

  	# @restaurantCategoryCountBreakdown = pie_chart(analyze.analyzeRestaurantCategoryCount)
  	# @restaurantCreationDateBreakdown = line_chart(analyze.analyzeRestaurantCreationDateCount)
  	# @restaurantCreationDateBreakdownText = analyze.analyzeRestaurantCreationDateCount.to_s

  	@eventTypesCount = pie_chart(analyze.analyzeEventsTypes)
  	
  	issuesCreatedMonthCount, issuesClosedMonthCount, issuesOpenCountPrep = analyze.analyzeIssuesCreatedClosedCountPerMonth
 	@issuesOpenCount = issuesOpenCountPrep[0]["number"]
 	@issuesCreatedClosedPerMonthCountGraph = line_chart [
															{:name => "Open", :data => issuesCreatedMonthCount},
															{:name => "Closed", :data => issuesClosedMonthCount},

														],:library => {:hAxis => {:format => 'MMM y'}} #TODO write blog post about dealing with the library function.  Add doc notes to Chartkick about accessing subfunctions.
	@issuesOpenClosedPerUsedPerMonth = analyze.analyzeIssuesOpenClosedPerUserPerMonth

	# TODO add sparklines
	@printableData = analyze.analyzeIssuesPrintableTable

	# puts analyze.analyzeIssuesOpenClosedPerUserPerMonth
	# puts "************************"
	# puts analyze.analyzeIssuesClosedDurationOpen
	# puts "************************"

	# Add inlcudeUnassigned = false to the analyzeIssuesAssignedCountPerUser Method arguments to not show unassigned issues
	openCount, closedCount = analyze.analyzeIssuesAssignedCountPerUser()

	# @issuesCountAssignedPerUserChart = bar_chart(analyze.analyzeIssuesAssignedCountPerUser)


		@issuesCountAssignedPerUserChart = column_chart [
														{:name => "Open", :data => openCount},
														{:name => "Closed", :data => closedCount},
													]

    erb :index
  end
end





# start = IssueDownload.new("CityofOttawa/Ottawa-ckan")
# start = IssueDownload.new("StephenOTT/Test1")
# start = IssueDownload.new("wet-boew/wet-boew-drupal")

# start.ghAuthenticate
# start.putIntoMongoCollIssues(start.getIssues)
# start.findIssuesWithComments
# start.putIntoMongoCollRepoEvents(start.getRepositoryEvents)
# start.getIssueEventsAllIssue
# start.putIntoMongoCollOrgMembers(start.getOrgMemberList)

MyApp.run!




# analyze = AnalyzeGHData.new()
# puts analyze.issueCommentsDatesBreakdownWeek(388, 2012)



# data = analyze.analyzeIssuesPrintableTable
# puts data






# puts analyze.analyzeEventsTypes
# puts "************************"
# puts analyze.analyzeIssuesCreatedClosedCountPerMonth
# puts "************************"
# puts analyze.analyzeIssuesOpenClosedPerUserPerMonth
# puts "************************"
# puts analyze.analyzeIssuesClosedDurationOpen
# puts "************************"
# puts analyze.analyzeIssuesAssignedCountPerUser

# issuesCreatedMonthCount, issuesClosedMonthCount, issuesOpenCountPrep = analyze.analyzeIssuesCreatedClosedCountPerMonth
# puts issuesCreatedMonthCount
# puts issuesClosedMonthCount
# puts issuesOpenCountPrep
# analyze.analyzeIssuesOpenClosedPerUserPerMonth
# analyze.analyzeEvents_IssueCommmentEvent


