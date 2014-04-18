require_relative 'github_data'
require_relative 'mongo'
require_relative 'convert_dates'

module Analytics_Download_Controller

	def self.controller(repo, object1, clearCollections = false, githubAuthInfo = {})
		# GitHub_Data.gh_authenticate(username, password)
		GitHub_Data.gh_sinatra_auth(object1)

		# MongoDb connection: DB URL, Port, DB Name, Collection Name
		Mongo_Connection.mongo_Connect("localhost", 27017, "GitHub-Analytics", "Issues-Data")
		
		# Clears the DB collections if clearCollections var in controller argument is true
		if clearCollections == true
			Mongo_Connection.clear_mongo_collections
		end

		#======Start of Issues=======
		issues = GitHub_Data.get_Issues(repo)
		
		
		# goes through each issue returned from get_Issues method
		issues.each do |i|
			# puts i
			i = Dates_Convert_For_MongoDB.convertIssueDatesForMongo(i)

			# Gets the comments for the specific issue
			issueComments = GitHub_Data.get_Issue_Comments(repo, i["number"])
			issueComments.each do |ic|
				ic = Dates_Convert_For_MongoDB.convertIssueCommentDatesInMongo(ic)
			end

			i["comments"] = issueComments
			i["downloaded_by_username"] = githubAuthInfo[:username]
			i["downloaded_by_userID"] = githubAuthInfo[:userID]
			i["repo"] = repo
			# Parses the specific issue for time tracking information
			# processedIssues = Gh_Issue.process_issue(repo, i, issueComments, githubAuthInfo)

			# if data is returned from the parsing attempt, the data is passed into MongoDb
			# if i.empty? == false
				Mongo_Connection.putIntoMongoCollTimeTrackingCommits(i)
			# end
		end
		#======End of Issues=======

	end
end



