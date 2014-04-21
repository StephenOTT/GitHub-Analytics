require_relative './mongo'
require 'date'
require "active_support/core_ext"


module Events_Aggregation

	def self.controller

		Mongo_Connection.mongo_Connect("localhost", 27017, "GitHub-Analytics", "Issues-Data")

	end

	def self.get_repo_issues_Events_per_month(repo, githubAuthInfo)
		
		repoIssueEvents = Mongo_Connection.aggregate_test([
			{ "$match" => {type: "Repo Issue Event"}},
			{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
			{"$project" => {_id: 1, 
							repo: 1,
							event: 1,
							created_month: {"$month" => "$created_at"}, 
							created_year: {"$year" => "$created_at"}, 
							}},			

			{ "$match" => { repo: repo }},

			{ "$group" => { _id: {
							repo: "$repo",
							event: "$event",
							created_year: "$created_year",
							created_month: "$created_month"},
							count: { "$sum" => 1 }
							}},
		    { "$sort" => {"_id.created_year" => 1, "_id.created_month" => 1}}
			])


		output = []
		
		repoIssueEvents.each do |x|
			x["_id"]["count"] = x["count"]
			x["_id"]["converted_date"] = DateTime.new(x["_id"]["created_year"], x["_id"]["created_month"])
			output << x["_id"]
		end

		# TODO build this out into its own method
		if output.empty? == false
			# Get Missing Months/Years from Date Range
			a = []
			output.each do |x|
				a << x["converted_date"]
			end
			b = (output.first["converted_date"]..output.last["converted_date"]).to_a
			zeroValueDates = (b.map{ |date| date.strftime("%b %Y") } - a.map{ |date| date.strftime("%b %Y") }).uniq
			
			zeroValueDates.each do |zvd|
				zvd = DateTime.parse(zvd)
				output << {"repo"=> repo, "created_year"=>zvd.strftime("%Y").to_i, "created_month"=>zvd.strftime("%m").to_i, "count"=>0, "converted_date"=>zvd}
			end
			# END of Get Missing Months/Years From Date Range
		end

		# Sorts the Output hash so the dates are in order
		output = output.sort_by { |hsh| [hsh["event"], hsh["converted_date"]] }
		return output
	end
end


# Debug code
# Events_Aggregation.controller
# puts Events_Aggregation.get_repo_issues_Events_per_month("StephenOTT/OPSEU", {:username => "StephenOTT", :userID => 1994838})



