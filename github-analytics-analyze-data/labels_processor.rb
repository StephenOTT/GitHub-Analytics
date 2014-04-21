require_relative 'labels_aggregation'
require_relative 'helpers'


module Labels_Processor

    def self.analyze_labels_count_for_repo(repo, githubAuthInfo)
      Labels_Aggregation.controller
      labelsCountForRepo = Labels_Aggregation.get_labels_count_for_repo(repo, githubAuthInfo)

      return labelsCountForRepo
    end


end