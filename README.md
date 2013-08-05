GitHub-Analytics
================

Downloads issues their comments from GitHub repositories into a mongodb database.

Analytics are then run on the issues and comments in the mongodb database.

Primary use at this point is project management based analytics that are not currently available on GitHub.com

-

###Types of Analysis:

1. Issues Closed (Count) per user.
2. Total comments made per user.
3. Breakdown of comments made referencing other users per user
	- example: Number of times a user references other users (breakdown of each user (histogram).
4. Issues per milestone.
5. Duration of issues open.
6. Avg time issues open/Time is takes to close.
7. Character count per post: avg per user, per issue, etc.
8. Issues opened and closed per min, hour, day, week, month, quarter, year.
9. Issues being watched
10. Most popular issues (most watched, most commented, etc)
11. Issues assigned to users
12. Counts of issues that are assigned to users and closed by the same user
13. Number of times issues are opened and closed repeatedly.
14. Sentiment analysis of issues and comments for that issue
	- Breakdown of sentiment per user and types of issues
	- Analysis of Issue Titles: Looking to have better descriptive titles.
15. Labels analysis
16. Assignment changes of issues: Visual of issue assignment changes per user and timeframe
17. Printable table breakdown of issues assigned to each user
18. Printable table breakdown of weekly activity metrics of specific users: HIGHLY used by old school PMs that staff often report to.
19. Milestone changes (Event Analysis) - Changes of milestone
20. Analysis of URLs being used in issues and comments (popular url mentions, number of github issues uploads etc)
21. Analysis of number of comments per issues before they are closed.
22. Analysis of Popular labels (has cloud implications if analysis becomes a service you could analyze popular labels across repos as well as their usage.
23. Comment Streaks and Issue Creation/Close streaks
	- Comments Streak: Number of times a user makes multiple comments one after another in a single issue.
24. Emoticon usage: PMs could say to use specific emoticons when they want to support something like "+1", and this can be tallied.
25. Task counts and usage analysis.
26. Events Analysis: Modification of Issues and Comments
	- Users that make the most modifications to Issues and Comments
	- Users that make the most modifications to their own posts vs others posts
	- Weekly breakdown of modifications made
	- Timeframe breakdown of modifications made when and by who.
27. Deleted comments: when, by who, whos posts, their own posts? etc.
28. Pintrest style breakdown of images in comments with links back to comments/issues and context for specific image.
29. Cross-Issue reference usage.  Most referenced Issues. Timeframe breakdown
30. Pie charts of issues and label assignment
31. Analysis of issues with more than one label
32. Analysis of Events and Label assignment
33. Change in milestone due dates
34. Change in milestone number of issues and %completed over time (line graph (%completed and time/dates)
35. Analysis of users on which teams: duration, added, removed dates, etc.
36. Breakdown of Repo Activity at high level: starts, forks, issues opened, closed, commits, etc.  Exec style printable report that provides a high level overview for review when in high level meetings.
37. Pull Requests: when, by who, refs of other issues, comments made, duration open, amount of code etc.
38. Creation of new repos
39. deletion of repos
40. Repos analysis: languages, teams, branches, tags, deletions of repos, contributors, etc.  Meant to be high level for reporting.



###Events Analysis:

1. hourly or daily download of events
2. types of events most popular, per user, etc.
3. Label Assignment
4. Milestone assignment




## To Do:

- [x] Downloading of Repo Events into Mongodb
- [ ] Convert to Rails app
- [ ] Downloading of Team data



## Future Analysis Mongodb queries:
---

1. Query for providing a breakdown of each of the different types of Events and the counts for each event type in the collection.

'''
db.githubRepoEvents.aggregate(  [    { $group : { _id : "$type" , Count : { $sum : 1 } } }  ])
'''



