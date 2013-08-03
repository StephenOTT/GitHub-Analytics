require 'octokit'
require 'json'



class IssueDownload

	def initialize (repository)
		
		@repository = repository
				
	end
	
	def ghAuthenticate
		puts "Enter GitHub Username:"
		username = gets
		
		# TODO Add Highline gem support for Password no-Echo
		puts "Enter GitHub Password:"
		password = gets
		
		
		@ghclient = Octokit::Client.new(:login => username.to_s, :password => password.to_s)		
	end
	
	
	def getIssues
		
		issueResults = Octokit.list_issues (@repository.to_s)
		return JSON.pretty_generate(issueResults.first)
	end
	


end

start = IssueDownload.new("CityofOttawa/Ottawa-ckan")
puts start.getIssues