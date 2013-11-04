require 'json'

class GenerateGDataTable

	def initialize
		@columnArray = []
		@rowArray = []
	end


	def addColumn(columnData={})
		@columnArray << {:id => columnData[:id], :label => columnData[:label], :type => columnData[:type] }
	end

	def addRow(rowData = [],hashValueName = "value", hashFormatName = "format", arrayValueNum = 0, arrayFormatNum = 1 )
		tempArray = []
		
		rowData.each do |x|
			if x.is_a?(Hash) == true
				tempArray << {:v => x[hashValueName], :f => x[hashFormatName]}

			elsif x.is_a?(Array) == true
				tempArray << {:v => x[arrayValueNum], :f => x[arrayFormatNum]}

			elsif x.is_a?(String) == true or x.is_a?(Integer) == true
				tempArray << {:v => x }
			end
		end

		@rowArray << {:c => tempArray}
	end

	def completeDataTable
		completedHash = {}
		completedHash[:cols] = @columnArray
		completedHash[:rows] = @rowArray
		return completedHash.to_json
	end
end

# dog = GenerateGDataTable.new
# dog.addColumn(:id => "dogName", :label => "Dog Name", :type => "string")
# dog.addRow(["Frank", "Steve", "Sam", "Cattle", [2222, "$24 222"], {"value" => 2222, "format" => "$24 222"}])
# puts dog.completeDataTable

