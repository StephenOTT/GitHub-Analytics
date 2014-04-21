# require 'chronic_duration'

module Helpers



def self.get_date_formatter(dateGroup)

	case dateGroup
		when :month
			return "%b %Y" # Month Year
		when :week
			return "Week %U, %Y" # Week Year
		when :day

	end

end


def self.get_missing_dates(repo, output, dateFormater)

	# dateFormater = "%b %Y" # Month Year
	# dateFormater = "Week %U, %Y" # Week Year

	
	# Add all dates into a array and sort from oldest to newest
	a = []
	output.each do |x|
		a << x["converted_date"]
	end
	a.sort!

	# Create a array of dates based on the date at the start of the "a" array and the last item int eh "a" array
	b = (output.first["converted_date"]..output.last["converted_date"]).to_a
	
	# remove dates that are the same in both "a" and "b" array, then remove duplicate values - output is array of strings
	zeroValueDates = (b.map{ |date| date.strftime(dateFormater) } - a.map{ |date| date.strftime(dateFormater) }).uniq

	# Iterates through each zeroValueDates array of Strings and parses back into a date and adds to the output array
	zeroValueDates.each do |zvd|
		zvd = DateTime.parse(zvd)
		output << {"repo"=> repo , "created_year"=>zvd.strftime("%Y").to_i, "created_month"=>zvd.strftime("%m").to_i, "count"=>0, "converted_date"=>zvd}
	end

	return output

end


def self.sort_dates_array_hash(arrayofHashes, sortField)

	arrayofHashes = arrayofHashes.sort_by { |hsh| hsh[sortField] }

end















	# def self.budget_left?(large, small)
	# 	large - small
	# end

	# def self.convertSecondsToDurationFormat(timeInSeconds, outputFormat)
	# 	outputFormat = outputFormat.to_sym
	# 	return ChronicDuration.output(timeInSeconds, :format => outputFormat, :keep_zero => true)
	# end


	# def self.merge_issue_time_and_budget(issuesTime, issuesBudget)

	# 	issuesTime.each do |t|

	# 		issuesBudget.each do |b|

	# 			if b["issue_number"] == t["issue_number"]
	# 				t["budget_duration_sum"] = b["budget_duration_sum"]
	# 				t["budget_comment_count"] = b["budget_comment_count"]
	# 				break
	# 			end					
	# 		end
	# 		if t.has_key?("budget_duration_sum") == false and t.has_key?("budget_comment_count") == false
	# 			t["budget_duration_sum"] = nil
	# 			t["budget_comment_count"] = nil
	# 		end
	# 	end

	# 	return issuesTime
	# end




	
end