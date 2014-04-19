# How to run the Web App:

1. Register/Create a Application at https://github.com/settings/applications/new.  Set your fields to the following:

	1.1. Homepage URL: `http://localhost:9292`

	1.2. Authorization callback URL: `http://localhost:9292/auth/github/callback`
	
	1.3. Application Name: `GitHub-Analytics` or whatever you want to call your application.

2. Install MongoDB (typically: `brew update`, followed by: `brew install mongodb`)

3. `cd` into the `app` folder and run the following commands in the `app` folder:

	3.1. Run `mongod` in terminal

	3.2. Open a second terminal window and run: `bundle install`
	
	3.3.`GITHUB_CLIENT_ID="YOUR CLIENT ID" GITHUB_CLIENT_SECRET="YOUR CLIENT SECRET" bundle exec rackup`
	Get the Client ID and Client Secret from the settings of your created/registered GitHub Application in Step 1.

4. Go to `http://localhost:9292`