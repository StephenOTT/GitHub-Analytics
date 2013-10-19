require './gh-issue-analyze.rb'
require 'sinatra'
require 'chartkick'

  get '/' do

    @foo = 'erb23'
    analyze = AnalyzeGHData.new()

  	@eventTypesCount = analyze.analyzeEventsTypes
  	
	@issueEventTypesCount = analyze.analyzeIssueEventsTypes

	# TODO Convert to Hash
	@issuesClosedEventHash, @issuesReopenedEventHash, @issuesSubscribedEventHash, @issuesMergedEventHash, @issuesReferencedEventHash, @issuesMentionedEventHash, @issuesAssignedEventHash = analyze.analyzeIssueEventsTypesOverTime

	# TODO Convert to Hash
	@createEvent, @forkEvent, @releaseEvent, @issueCommentEvent, @watchEvent, @issuesEvent, @pushEvent, @commitCommentEvent, @pullRequestEvent = analyze.analyzeEventsTypesOverTime

  	@issuesCreatedMonthCount, @issuesClosedMonthCount, @issuesOpenCountPrep = analyze.analyzeIssuesCreatedClosedCountPerMonth
	@issuesOpenClosedPerUsedPerMonth = analyze.analyzeIssuesOpenClosedPerUserPerMonth

	@printableData = analyze.analyzeIssuesPrintableTable

	# Add inlcudeUnassigned = false to the analyzeIssuesAssignedCountPerUser Method arguments to not show unassigned issues
	# TODO Convert to Hash
	@issueAssignedPerUserOpenCount, @issueAssignedPerUserClosedCount = analyze.analyzeIssuesAssignedCountPerUser()

    erb :index
  end