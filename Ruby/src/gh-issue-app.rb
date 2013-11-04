require './gh-issue-analyze.rb'
# require './Test.rb'
require 'sinatra'
require "sinatra/reloader" if development?
require 'chartkick'
# require '../../../chartkick/lib/chartkick.rb'

  get '/' do

    @foo = 'erb23' # Debug code
    
    analyze = AnalyzeGHData.new()
    # generateData = GenerateGDataTable.new()
    # generateData.addColumn(:id => "col1", :label => "Dogs Generated1", :type => "number")
    # generateData.addColumn(:id => "col2", :label => "Dogs Generated2", :type => "number")
    # generateData.addRow([2004,0])
    # generateData.addRow([2005,22])
    # generateData.addRow([2006,50])
    # generateData.addRow([2007,100])
    # generateData.addRow([2008,40])
    # generateData.addRow([2009,70])
    # generateData.addRow([2010,10])
    # generateData.addRow([2011,90])
    # generateData.addRow([2012,40])

    # @sampleChart = generateData.completeDataTable
    # puts @sampleChart


  	@eventTypesCount = analyze.analyzeEventsTypes
  	# @eventstext = analyze.analyzeEventsTypes.to_a.to_s
  	
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

    # @timelineTest = [
    #                     ['Washington',0,23],
    #                     ['Adams',0,5],
    #                     ['Jefferson',0,50]]




    erb :index
  end