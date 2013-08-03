require 'octokit'
require 'json'
require 'mongo'

include Mongo


class IssueDownload


	def initialize (repository)
		
		@repository = repository
		
		# MongoDB Database Connect
		@client = MongoClient.new('localhost', 27017)
		@db = @client['test']
		@coll = @db['githubIssues']
		@coll.remove		
		@collComments = @db['githubComments']
		@collComments.remove		
	
	end
	
	def ghAuthenticate
		puts "Enter GitHub Username:"
		username = gets
		
		# TODO Add Highline gem support for Password no-Echo
		puts "Enter GitHub Password:"
		password = gets
		
		
		#@ghclient = Octokit::Client.new(:login => username.to_s, :password => password.to_s)		
	end
	
	
	def getIssues
		
		# Auto-Pagination feature that increments through all pages of issues:
		# See: http://rdoc.info/gems/octokit/Octokit/Configuration#DEFAULT_AUTO_TRAVERSAL-constant
		# See:https://github.com/octokit/octokit.rb/pull/64 
		Octokit.configure do |c|
  		c.auto_traversal = true
		end
		
		
		issueResults = Octokit.list_issues (@repository.to_s)
		#return JSON.pretty_generate(issueResults.first)
		return issueResults
	end
	
	
	def putIntoMongo
		@coll.insert(getIssues)
		
	
	end
	
	
	# find records in Mongodb that have a comments field value of 1 or higher
	# returns only the number field
	def findIssuesWithComments
	
		self.ghConfigAutoTraversal
	
		#find filter is based on: http://stackoverflow.com/a/10443659
		issuesWithComments = @coll.find({"comments" => {"$gt" => 0}}, {:fields => {"_id" => 0, "number" => 1}}).to_a
		
		issuesWithComments.each do |x|
 			 puts x["number"]
 			 issueComments = Octokit.issue_comments(@repository.to_s, x["number"].to_s)
 			 @collComments.insert(issueComments)
		end 
				

end


end

start = IssueDownload.new("wet-boew/wet-boew")
#puts start.getIssues
start.putIntoMongo