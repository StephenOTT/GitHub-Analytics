require_relative './mongo'
require 'date'
require "active_support/core_ext"


module Issues_Aggregation

	def self.controller

		Mongo_Connection.mongo_Connect("localhost", 27017, "GitHub-Analytics", "Issues-Data")

	end

	def self.get_issues_opened_per_user(repo, githubAuthInfo)
		totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
			{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
			{"$project" => {number: 1, 
							_id: 1, 
							repo: 1,  
							user: { login: 1}}},			
			{ "$match" => { repo: repo }},
			{ "$group" => { _id: {
							repo: "$repo",
							user: "$user.login",},
							issues_opened_count: { "$sum" => 1 }
							}}])
		output = []
		totalIssueSpentHoursBreakdown.each do |x|
			x["_id"]["issues_opened_count"] = x["issues_opened_count"]
			# x["_id"]["time_comment_count"] = x["time_comment_count"]
			output << x["_id"]
		end
		return output
	end

	def self.get_issues_created_per_month(repo, githubAuthInfo)
		totalIssuesOpen = Mongo_Connection.aggregate_test([
			{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
			# { "$match" => {state: { 
			# 							"$ne" => "closed"
			# 							}}},
			{"$project" => {number: 1, 
							_id: 1, 
							repo: 1,
							state: 1,
							created_at: 1,
							# closed_at: 1,
							created_month: {"$month" => "$created_at"}, 
							created_year: {"$year" => "$created_at"}, 
							# closed_month: {"$month" => "$closed_at"}, 
							# closed_year: {"$year" => "$closed_at"}
							}},			

			{ "$match" => { repo: repo }},

			{ "$group" => { _id: {
							repo: "$repo",
							# state: "$state",
							# user: "$user.login",},
							created_year: "$created_year",
							created_month: "$created_month"},
							issues_opened_count: { "$sum" => 1 }
							}},
		    { "$sort" => {"_id.created_year" => 1, "_id.created_month" => 1}}
			])

		output = []
		totalIssuesOpen.each do |x|
			x["_id"]["count"] = x["issues_opened_count"]
			x["_id"]["converted_date"] = DateTime.new(x["_id"]["created_year"], x["_id"]["created_month"])
			# x["_id"]["date1"] = Date.new(x["_id"]["created_year"],2,3) 
			output << x["_id"]
		end

		# TODO build this out into its own method to ensure DRY.
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
				output << {"repo"=> repo , "state"=>"open", "created_year"=>zvd.strftime("%Y").to_i, "created_month"=>zvd.strftime("%m").to_i, "count"=>0, "converted_date"=>zvd}
			end
			# END of Get Missing Months/Years From Date Range
		end

		# Sorts the Output hash so the dates are in order
		output = output.sort_by { |hsh| hsh["converted_date"] }
		return output
	end

	def self.get_issues_closed_per_month(repo, githubAuthInfo)
		
		totalIssuesClosed = Mongo_Connection.aggregate_test([
			{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
			{ "$match" => {state: { 
										"$ne" => "open" 
										}}},
			{"$project" => {number: 1, 
							_id: 1, 
							repo: 1,
							# state: 1,
							# created_at: 1,
							closed_at: 1,
							closed_month: {"$month" => "$closed_at"}, 
							closed_year: {"$year" => "$closed_at"}, 
							# closed_month: {"$month" => "$closed_at"}, 
							# closed_year: {"$year" => "$closed_at"}
							}},			

			{ "$match" => { repo: repo }},

			{ "$group" => { _id: {
							repo: "$repo",
							# state: "$state",
							# user: "$user.login",},
							closed_year: "$closed_year",
							closed_month: "$closed_month"},
							issues_opened_count: { "$sum" => 1 }
							}},
		    { "$sort" => {"_id.closed_year" => 1, "_id.closed_month" => 1}}
			])


		output = []
		
		totalIssuesClosed.each do |x|
			x["_id"]["count"] = x["issues_opened_count"]
			x["_id"]["converted_date"] = DateTime.new(x["_id"]["closed_year"], x["_id"]["closed_month"])
			# x["_id"]["date1"] = Date.new(x["_id"]["created_year"],2,3) 
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
				output << {"repo"=> repo , "state"=>"closed", "closed_year"=>zvd.strftime("%Y").to_i, "closed_month"=>zvd.strftime("%m").to_i, "count"=>0, "converted_date"=>zvd}
			end
			# END of Get Missing Months/Years From Date Range
		end

		# Sorts the Output hash so the dates are in order
		output = output.sort_by { |hsh| hsh["converted_date"] }
		return output
	end




	# def self.get_issues_created_closed_per_month
		
	# 	issuesCreatedPerMonth = @collIssues.aggregate([
	# 		{ "$match" => {closed_at: {"$ne" => nil}}},
	# 	    { "$project" => {created_month: {"$month" => "$created_at"}, created_year: {"$year" => "$created_at"}, closed_month: {"$month" => "$closed_at"}, closed_year: {"$year" => "$closed_at"}, state: 1}},
	# 	    { "$group" => {_id: {"created_month" => "$created_month", "created_year" => "$created_year", state: "$state", "closed_month" => "$closed_month", "closed_year" => "$closed_year"}, number: { "$sum" => 1 }}},
	# 	    #{ "$sort" => {"_id.created_month" => 1}}
	# 	])

	# 	issuesOpenCount = @collIssues.aggregate([
	# 		{ "$match" => {state: {"$ne" => "closed"}}},
	# 	    { "$project" => {state: 1}},
	# 	    { "$group" => {_id: {state: "$state"}, number: { "$sum" => 1 }}},
	# 	])

	# 	newHashOpened={}
	# 	newHashClosed={}
	# 	issuesCreatedPerMonth.each do |x|
	# 			newHashOpened[Date.strptime(x["_id"].values_at('created_month', 'created_year').join(" "), '%m %Y')] = x["number"]
			
	# 		if x["_id"]["closed_month"] != nil
	# 			newHashClosed[Date.strptime(x["_id"].values_at('closed_month', 'closed_year').join(" "), '%m %Y')] = x["number"]
	# 		end
	# 	end

	# 	dateConvert = DateManipulate.new()

	# 	return dateConvert.sortHashPlain(newHashOpened), dateConvert.sortHashPlain(newHashClosed), issuesOpenCount
	# end







	# def self.get_issue_time(repo, issueNumber, githubAuthInfo)
	# 	totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
	# 		{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
	# 		{"$project" => {type: 1, 
	# 						issue_number: 1, 
	# 						_id: 1, 
	# 						repo: 1,
	# 						milestone_number: 1, 
	# 						issue_state: 1, 
	# 						issue_title: 1, 
	# 						time_tracking_commits:{ duration: 1, 
	# 												type: 1, 
	# 												comment_id: 1 }}},
	# 		{ "$match" => { repo: repo }},			
	# 		{ "$match" => { type: "Issue" }},
	# 		{ "$match" => {issue_number: issueNumber.to_i}},
	# 		{ "$unwind" => "$time_tracking_commits" },
	# 		{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Time"] }}},
	# 		{ "$group" => { _id: {
	# 						repo_name: "$repo",
	# 						milestone_number: "$milestone_number",
	# 						issue_number: "$issue_number",
	# 						issue_title: "$issue_title",
	# 						issue_state: "$issue_state", },
	# 						time_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
	# 						time_comment_count: { "$sum" => 1 }
	# 						}}
	# 						])
	# 	output = []
	# 	totalIssueSpentHoursBreakdown.each do |x|
	# 		x["_id"]["time_duration_sum"] = x["time_duration_sum"]
	# 		x["_id"]["time_comment_count"] = x["time_comment_count"]
	# 		output << x["_id"]
	# 	end
	# 	return output
	# end




	# # old name: analyze_issue_budget_hours
	# def self.get_all_issues_budget(repo, githubAuthInfo)
	# 	totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
	# 		{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
	# 		{"$project" => {type: 1, 
	# 						issue_number: 1, 
	# 						_id: 1, 
	# 						repo: 1,
	# 						milestone_number: 1, 
	# 						issue_state: 1, 
	# 						issue_title: 1, 
	# 						time_tracking_commits:{ duration: 1, 
	# 												type: 1, 
	# 												comment_id: 1 }}},
	# 		{ "$match" => { repo: repo }},
	# 		{ "$match" => { type: "Issue" }},
	# 		{ "$unwind" => "$time_tracking_commits" },
	# 		{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Budget"] }}},
	# 		{ "$group" => { _id: {
	# 						repo_name: "$repo",
	# 						milestone_number: "$milestone_number",
	# 						issue_number: "$issue_number",
	# 						issue_state: "$issue_state",
	# 						issue_title: "$issue_title",},
	# 						budget_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
	# 						budget_comment_count: { "$sum" => 1 }
	# 						}}
	# 						])
	# 	output = []
	# 	totalIssueSpentHoursBreakdown.each do |x|
	# 		x["_id"]["budget_duration_sum"] = x["budget_duration_sum"]
	# 		x["_id"]["budget_comment_count"] = x["budget_comment_count"]
	# 		output << x["_id"]
	# 	end
	# 	return output
	# end


	# def self.get_issue_budget(repo, issueNumber, githubAuthInfo)
	# 	totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
	# 		{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
	# 		{"$project" => {type: 1, 
	# 						issue_number: 1, 
	# 						_id: 1, 
	# 						repo: 1,
	# 						milestone_number: 1, 
	# 						issue_state: 1, 
	# 						issue_title: 1, 
	# 						time_tracking_commits:{ duration: 1, 
	# 												type: 1, 
	# 												comment_id: 1 }}},			
	# 		{ "$match" => { repo: repo }},			
	# 		{ "$match" => { type: "Issue" }},
	# 		{ "$match" => {issue_number: issueNumber.to_i}},
	# 		{ "$unwind" => "$time_tracking_commits" },
	# 		{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Budget"] }}},
	# 		{ "$group" => { _id: {
	# 						repo_name: "$repo",
	# 						milestone_number: "$milestone_number",
	# 						issue_number: "$issue_number",
	# 						issue_state: "$issue_state",
	# 						issue_title: "$issue_title",},
	# 						budget_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
	# 						budget_comment_count: { "$sum" => 1 }
	# 						}}
	# 						])
	# 	output = []
	# 	totalIssueSpentHoursBreakdown.each do |x|
	# 		x["_id"]["budget_duration_sum"] = x["budget_duration_sum"]
	# 		x["_id"]["budget_comment_count"] = x["budget_comment_count"]
	# 		output << x["_id"]
	# 	end
	# 	return output
	# end




	# def self.get_all_issues_time_in_milestone(repo, milestoneNumber, githubAuthInfo)
	# 	totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
	# 		{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
	# 		{"$project" => {type: 1, 
	# 						issue_number: 1, 
	# 						_id: 1, 
	# 						repo: 1,
	# 						milestone_number: 1, 
	# 						issue_state: 1, 
	# 						issue_title: 1, 
	# 						time_tracking_commits:{ duration: 1, 
	# 												type: 1, 
	# 												comment_id: 1 }}},			
	# 		{ "$match" => { repo: repo }},			
	# 		{ "$match" => { type: "Issue" }},
	# 		{ "$match" => { milestone_number: milestoneNumber.to_i }},
	# 		{ "$unwind" => "$time_tracking_commits" },
	# 		{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Time"] }}},
	# 		{ "$group" => { _id: {
	# 						repo_name: "$repo",
	# 						milestone_number: "$milestone_number",
	# 						issue_number: "$issue_number",
	# 						issue_title: "$issue_title",
	# 						issue_state: "$issue_state", },
	# 						time_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
	# 						time_comment_count: { "$sum" => 1 }
	# 						}}
	# 						])
	# 	output = []
	# 	totalIssueSpentHoursBreakdown.each do |x|
	# 		x["_id"]["time_duration_sum"] = x["time_duration_sum"]
	# 		x["_id"]["time_comment_count"] = x["time_comment_count"]
	# 		output << x["_id"]
	# 	end
	# 	return output
	# end



	# def self.get_total_issues_time_for_milestone(repo, milestoneNumber, githubAuthInfo)
	# 	totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
	# 		{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
	# 		{"$project" => {type: 1, 
	# 						issue_number: 1, 
	# 						_id: 1, 
	# 						repo: 1,
	# 						milestone_number: 1, 
	# 						issue_state: 1, 
	# 						issue_title: 1, 
	# 						time_tracking_commits:{ duration: 1, 
	# 												type: 1, 
	# 												comment_id: 1 }}},			
	# 		{ "$match" => { repo: repo }},			
	# 		{ "$match" => { type: "Issue" }},
	# 		{ "$match" => { milestone_number: milestoneNumber.to_i }},
	# 		{ "$unwind" => "$time_tracking_commits" },
	# 		{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Time"] }}},
	# 		{ "$group" => { _id: {
	# 						repo_name: "$repo",
	# 						milestone_number: "$milestone_number"},
	# 						time_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
	# 						time_comment_count: { "$sum" => 1 }
	# 						}}
	# 						])
	# 	output = []
	# 	totalIssueSpentHoursBreakdown.each do |x|
	# 		x["_id"]["time_duration_sum"] = x["time_duration_sum"]
	# 		x["_id"]["time_comment_count"] = x["time_comment_count"]
	# 		output << x["_id"]
	# 	end
	# 	return output
	# end





	# def self.get_all_issues_budget_in_milestone(repo, milestoneNumber, githubAuthInfo)
	# 	totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
	# 		{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
	# 		{"$project" => {type: 1, 
	# 						issue_number: 1, 
	# 						_id: 1, 
	# 						repo: 1,
	# 						milestone_number: 1, 
	# 						issue_state: 1, 
	# 						issue_title: 1, 
	# 						time_tracking_commits:{ duration: 1, 
	# 												type: 1, 
	# 												comment_id: 1 }}},			
	# 		{ "$match" => { repo: repo }},
	# 		{ "$match" => { type: "Issue" }},
	# 		{ "$match" => { milestone_number: milestoneNumber.to_i }},
	# 		{ "$unwind" => "$time_tracking_commits" },
	# 		{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Budget"] }}},
	# 		{ "$group" => { _id: {
	# 						repo_name: "$repo",
	# 						milestone_number: "$milestone_number",
	# 						issue_number: "$issue_number",
	# 						issue_state: "$issue_state",
	# 						issue_title: "$issue_title",},
	# 						budget_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
	# 						budget_comment_count: { "$sum" => 1 }
	# 						}}
	# 						])
	# 	output = []
	# 	totalIssueSpentHoursBreakdown.each do |x|
	# 		x["_id"]["budget_duration_sum"] = x["budget_duration_sum"]
	# 		x["_id"]["budget_comment_count"] = x["budget_comment_count"]
	# 		output << x["_id"]
	# 	end
	# 	return output
	# end


	# # Get repo sum of issue time
	# def self.get_repo_time_from_issues(repo, githubAuthInfo)
	# 	totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
	# 		{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
	# 		{"$project" => {type: 1, 
	# 						issue_number: 1, 
	# 						_id: 1, 
	# 						repo: 1,
	# 						milestone_number: 1, 
	# 						issue_state: 1, 
	# 						issue_title: 1, 
	# 						time_tracking_commits:{ duration: 1, 
	# 												type: 1, 
	# 												comment_id: 1 }}},			
	# 		{ "$match" => { repo: repo }},
	# 		{ "$match" => { type: "Issue" }},
	# 		{ "$unwind" => "$time_tracking_commits" },
	# 		{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Time"] }}},
	# 		{ "$group" => { _id: {
	# 						repo_name: "$repo"},
	# 						time_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
	# 						time_comment_count: { "$sum" => 1 }
	# 						}}
	# 						])
	# 	output = []
	# 	totalIssueSpentHoursBreakdown.each do |x|
	# 		x["_id"]["time_duration_sum"] = x["time_duration_sum"]
	# 		x["_id"]["time_comment_count"] = x["time_comment_count"]
	# 		output << x["_id"]
	# 	end
	# 	return output
	# end

	# # Sums all issue budgets for the repo and outputs the total budget based on issues
	# def self.get_repo_budget_from_issues(repo, githubAuthInfo)
	# 	totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
	# 		{ "$match" => { downloaded_by_username: githubAuthInfo[:username], downloaded_by_userID: githubAuthInfo[:userID] }},
	# 		{"$project" => {type: 1, 
	# 						issue_number: 1, 
	# 						_id: 1, 
	# 						repo: 1,
	# 						milestone_number: 1, 
	# 						issue_state: 1, 
	# 						issue_title: 1, 
	# 						time_tracking_commits:{ duration: 1, 
	# 												type: 1, 
	# 												comment_id: 1 }}},			
	# 		{ "$match" => { repo: repo }},
	# 		{ "$match" => { type: "Issue" }},
	# 		{ "$unwind" => "$time_tracking_commits" },
	# 		{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Budget"] }}},
	# 		{ "$group" => { _id: {
	# 						repo_name: "$repo"},
	# 						budget_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
	# 						budget_comment_count: { "$sum" => 1 }
	# 						}}
	# 						])
	# 	output = []
	# 	totalIssueSpentHoursBreakdown.each do |x|
	# 		x["_id"]["budget_duration_sum"] = x["budget_duration_sum"]
	# 		x["_id"]["budget_comment_count"] = x["budget_comment_count"]
	# 		output << x["_id"]
	# 	end
	# 	return output
	# end
end


# Debug code
# Issues_Aggregation.controller
# puts Issues_Aggregation.get_issues_opened_per_user("StephenOTT/Test1", {:username => "StephenOTT", :userID => 1994838})
# puts Issues_Aggregation.get_issues_created_per_month("StephenOTT/OPSEU", {:username => "StephenOTT", :userID => 1994838})
# puts Issues_Aggregation.get_issues_closed_per_month("StephenOTT/OPSEU", {:username => "StephenOTT", :userID => 1994838})



