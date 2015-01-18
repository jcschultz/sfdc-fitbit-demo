/*
 * @author John Schultz, salesforce.com
 * @date January 16, 2015
 * @description Class for handling Fitbit Oauth interactions
 * @log:
 *	-----------------------------------------------------------------------------
 *	Developer			Date		Description
 *	-----------------------------------------------------------------------------
 *	John Schultz		2015-01-16	Newly created
 */

public class FitbitOauth {
	private Fitbit_API__c apiSettings;
	private User userData;
	
	public FitbitOauth(String userId) {
		getFitbitSettings();
		getUserToken(userId);
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Getter for Fitbit API settings
	* @return: Fitbit_API__c
	*/
	public Fitbit_API__c getApiSettings() {
		return apiSettings;
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Getter for user data and tokens
	* @return: User
	*/
	public User getUserData() {
		return userData;
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Gets the temporary tokens and redirects to the authorization page.
	* @return: pRef - Redirection to authorization page
	*/
	public PageReference getAuthorization() {
		String tempToken;
		String tempSecret;
		PageReference pRef = null;
		Map<String, String> params = new Map<String, String>();
		String timeStamp = generateTimeStamp();
		
		params.put('oauth_callback', URL.getSalesforceBaseUrl().toExternalForm() + '/apex/FitbitCallback');
		params.put('oauth_consumer_key',  apiSettings.Client_Key__c);
		params.put('oauth_nonce', 'nONce' + timeStamp);
		params.put('oauth_signature_method', 'HMAC-SHA1');
		params.put('oauth_timestamp', timeStamp);
		params.put('oauth_version', '1.0');
		params.put('oauth_signature', generateSignature(params, 'POST', apiSettings.Temporary_Credentials_URL__c, null));
		
		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setEndpoint(apiSettings.Temporary_Credentials_URL__c);
		req.setHeader('Authorization', generateAuthHeader(params));
		
		HttpResponse res = new Http().send(req);
		
		if (res.getStatusCode() > 299) {
			handleError('Error getting authorization.', res, req);
		}
		else {
			for (String s : res.getBody().split('&')) {
				List<String> pair = s.split('=');
				
				if (pair[0] == 'oauth_token') {
					tempToken = pair[1];
				}
				else if (pair[0] == 'oauth_token_secret') {
					userData.Fitbit_Oauth_Token_Secret__c = pair[1];
					update userData;
				}
			}
			
			pRef = new PageReference(apiSettings.Authorize_URL__c + '?oauth_token=' + tempToken);
			pRef.setRedirect(true);
		}
		
		return pRef;
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Uses temporary token and verifier to request the real tokens
	* @param: tempToken - String. Temporary token
	* @param: verifier - String. Code used during initial auth request
	* @return: void
	*/
	public void requestTokens(String tempToken, String verifier) {
		Map<String, String> params = new Map<String, String>();
		String timeStamp = generateTimeStamp();
		
		params.put('oauth_consumer_key',  apiSettings.Client_Key__c);
		params.put('oauth_nonce', 'nONce' + timeStamp);
		params.put('oauth_signature_method', 'HMAC-SHA1');
		params.put('oauth_timestamp', timeStamp);
		params.put('oauth_token', tempToken);
		params.put('oauth_verifier', verifier);
		params.put('oauth_version', '1.0');
		params.put('oauth_signature', generateSignature(params, 'POST', apiSettings.Token_Credentials_URL__c, userData.Fitbit_Oauth_Token_Secret__c));
		
		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setEndpoint(apiSettings.Token_Credentials_URL__c);
		req.setHeader('Authorization', generateAuthHeader(params));
		
		HttpResponse res = new Http().send(req);
		
		if (res.getStatusCode() > 299) {
			handleError('Error retrieving tokens.', res, req);
		}
		else {
			for (String s : res.getBody().split('&')) {
				List<String> pair = s.split('=');
				
				if (pair[0] == 'oauth_token') {
					userData.Fitbit_Oauth_Token__c = pair[1];
				}
				else if (pair[0] == 'oauth_token_secret') {
					userData.Fitbit_Oauth_Token_Secret__c = pair[1];
				}
			}
			
			update userData;
		}
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-17
	* @description: Makes a call to fitbit api to get the activities for the specified date and stores the data in a Fitbit_Activity__c record.
	* @param: activityDate - String of date in YYYY-MM-DD format
	* @return: Id of the Fitbit_Activity__c record that is created/edited
	*/
	public String getActivities(String activityDate) {
		if (String.isBlank(activityDate)) {
			throw new FitbitOauthException('Activity date format is incorrect. It must be in YYYY-MM-DD format.');
		}
		
		String activityId;
		Map<String, String> params = new Map<String, String>();
		String timeStamp = generateTimeStamp();
		String apiUrl = apiSettings.Get_Activities_URL__c;
		apiUrl = apiUrl.replace('{{date}}', activityDate);
		
		params.put('oauth_consumer_key',  apiSettings.Client_Key__c);
		params.put('oauth_nonce', 'nONce' + timeStamp);
		params.put('oauth_signature_method', 'HMAC-SHA1');
		params.put('oauth_timestamp', timeStamp);
		params.put('oauth_token', userData.Fitbit_Oauth_Token__c);
		params.put('oauth_version', '1.0');
		params.put('oauth_signature', generateSignature(params, 'GET', apiUrl, userData.Fitbit_Oauth_Token_Secret__c));
		
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint(apiUrl);
		req.setHeader('Authorization', generateAuthHeader(params));
		
		HttpResponse res = new Http().send(req);
		
		if (res.getStatusCode() > 299) {
			handleError('Error retrieving activities.', res, req);
		}
		else {
			Goals jsonGoals;
			Summary jsonSummary;
			
			JSONParser parser = JSON.createParser(res.getBody());
			
			while(parser.nextToken() != null) {
				if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'goals') {
					jsonGoals = (Goals)parser.readValueAs(Goals.class);
					parser.skipChildren();
				}
				else if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'summary') {
					jsonSummary = (Summary)parser.readValueAs(Summary.class);
					parser.skipChildren();
				}
			}
			
			if (jsonGoals != null) {
				userData.Fitbit_Goal_Active_Minutes__c = jsonGoals.activeMinutes;
				userData.Fitbit_Goal_Calories_Out__c = jsonGoals.caloriesOut;
				userData.Fitbit_Goal_Distance__c = jsonGoals.distance;
				userData.Fitbit_Goal_Floors__c = jsonGoals.floors;
				userData.Fitbit_Goal_Steps__c = jsonGoals.steps;
				
				try {
					update userData;
				}
				catch (Exception e) {
					throw new FitbitOauthException('There was an error saving the Fitbit goals to the user record. Error: ' + e.getMessage());
				}
			}
			
			if (jsonSummary != null) {
				Fitbit_Activity__c fba;
				Date dateFormatted;
				
				List<String> dateParts = activityDate.split('-');
				dateFormatted = date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
				
				// first try to find a Fitbit activity record for this user with a matching date
				try {
					fba = [SELECT Id, Active_Score__c, Activity_Calories__c, Calories_BMR__c, Calories_Out__c, Date__c, Elevation__c, Fairly_Active_Minutes__c, Floors__c, Lightly_Active_Distance__c, Lightly_Active_Minutes__c, Logged_Activities_Distance__c, Marginal_Calories__c, Moderately_Active_Distance__c, Sedentary_Active_Distance__c, Sedentary_Minutes__c, Steps__c, Total_Distance__c, Tracker_Distance__c, User__c, Very_Active_Distance__c, Very_Active_Minutes__c FROM Fitbit_Activity__c WHERE User__c =: userData.Id AND Date__c =: dateFormatted LIMIT 1];
				}
				catch (Exception e){
					fba = new Fitbit_Activity__c();
				}
				
				fba.Active_Score__c = jsonSummary.activeScore;
				fba.Activity_Calories__c = jsonSummary.activityCalories;
				fba.Calories_BMR__c = jsonSummary.caloriesBMR;
				fba.Calories_Out__c = jsonSummary.caloriesOut;
				fba.Date__c = dateFormatted;
				fba.Elevation__c = jsonSummary.elevation;
				fba.Fairly_Active_Minutes__c = jsonSummary.fairlyActiveMinutes;
				fba.Floors__c = jsonSummary.floors;
				fba.Lightly_Active_Distance__c = jsonSummary.getDistance('lightlyActive');
				fba.Lightly_Active_Minutes__c = jsonSummary.lightlyActiveMinutes;
				fba.Logged_Activities_Distance__c = jsonSummary.getDistance('loggedActivities');
				fba.Marginal_Calories__c = jsonSummary.marginalCalories;
				fba.Moderately_Active_Distance__c = jsonSummary.getDistance('moderatelyActive');
				fba.Sedentary_Active_Distance__c = jsonSummary.getDistance('sedentaryActive');
				fba.Sedentary_Minutes__c = jsonSummary.sedentaryMinutes;
				fba.Steps__c = jsonSummary.steps;
				fba.Total_Distance__c = jsonSummary.getDistance('total');
				fba.Tracker_Distance__c = jsonSummary.getDistance('tracker');
				fba.User__c = userData.Id;
				fba.Very_Active_Distance__c = jsonSummary.getDistance('veryActive');
				fba.Very_Active_Minutes__c = jsonSummary.veryActiveMinutes;
				
				try {
					upsert fba;
					activityId = fba.Id;
				}
				catch (Exception e) {
					throw new FitbitOauthException('There was an error saving the Fitbit activity. Error: ' + e.getMessage());
				}
			}
		}
		
		return activityId;
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Generates the signature
	* @param: params - Map of key-value pairs of parameters
	* @param: method - String. Method of http request
	* @param: url - Url of request
	* @param: secret - String. The temp secret used during permanent access token. Null otherwise.
	* @return: String
	*/
	private String generateSignature(Map<String, String> params, String method, String url, String secret) {
		String base = method + '&' + EncodingUtil.urlEncode(url, 'UTF-8') + '&';
		String base2 = '';
		
		List<String> keys = new List<String>();
		keys.addAll(params.keySet());
		keys.sort();
		
		for (Integer i = 0; i < keys.size(); i++) {
			String param = params.get(keys.get(i));
			
			if (keys.get(i) == 'oauth_callback') {
				param = EncodingUtil.urlEncode(param, 'UTF-8');
			}
			
			base2 += keys.get(i) + '=' + param;
			
			if (i < keys.size()-1) {
				base2 += '&';
			}
		}
		
		String cryptoKey = apiSettings.Client_Secret__c + '&';
		
		if (String.isNotBlank(secret)) {
			cryptoKey += secret;
		}
		
		String signatureBaseString = base + EncodingUtil.urlEncode(base2, 'UTF-8');
		Blob sigBlob = Crypto.generateMac('HmacSHA1', Blob.valueOf(signatureBaseString), Blob.valueOf(cryptoKey));
		String signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sigBlob), 'UTF-8');
		
		return signature;
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Generates the authorization header
	* @param: params - Map of key-value pairs of parameters
	* @return: String
	*/
	private String generateAuthHeader(Map<String, String> params) {
		String authHeader = 'OAuth ';
		
		List<String> keys = new List<String>();
		keys.addAll(params.keySet());
		keys.sort();
		
		for (Integer i = 0; i < keys.size(); i++) {
			authHeader += keys.get(i) + '="' + params.get(keys.get(i)) + '"';
			
			if (i < keys.size()-1) {
				authHeader += ', ';
			}
		}
		
		return authHeader;
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-17
	* @description: Generates the 10 digit timestamp
	* @return: String
	*/
	private String generateTimeStamp() {
		String timeStamp = '' + DateTime.now().getTime();
		return timeStamp.left(10);
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Retrieves the fitbit api custom setting info
	* @return: void
	*/
	private void getFitbitSettings() {
		try {
			apiSettings = [SELECT Authorize_URL__c, Client_Key__c, Client_Secret__c, Temporary_Credentials_URL__c, Token_Credentials_URL__c, Get_Activities_URL__c FROM Fitbit_API__c LIMIT 1];
		}
		catch (Exception e) {
			throw new FitbitOauthException('The Fitbit OAuth Service has not yet been created. Your System Administrator must first set that up.');
		}
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-17
	* @description: Handles error responses
	* @param: errorMsg - String. Message to be displayed before error details.
	* @param: res - HttpResponse
	* @param: req - HttpRequest
	* @return: void
	*/
	private void handleError(String errorMsg, HttpResponse res, HttpRequest req) {
		System.debug('@@JOHN@@ body:' + req.getBody());
		System.debug('@@JOHN@@ method:' + req.getMethod());
		System.debug('@@JOHN@@ authorization header:' + req.getHeader('Authorization'));
		System.debug('@@JOHN@@ endpoint: ' + req.getEndpoint());
		System.debug('@@JOHN@@ Response: ' + res.getBody());
		
		throw new FitbitOauthException(errorMsg + ' Status:' + res.getStatus() + '. Response:' + res.getBody());
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Retrieves the token and token secret for the user
	* @param: userId - String of the user id for the user whose token you wish to retrieve
	* @return: void
	*/
	private void getUserToken(String userId) {
		userData = [SELECT Id, Fitbit_Oauth_Token__c, Fitbit_Oauth_Token_Secret__c, Fitbit_Goal_Active_Minutes__c, Fitbit_Goal_Calories_Out__c, Fitbit_Goal_Distance__c, Fitbit_Goal_Floors__c, Fitbit_Goal_Steps__c FROM User WHERE Id =: userId LIMIT 1];
	}
	
	
	public class FitbitOauthException extends Exception {}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-17
	* @description: Inner class for JSON activity goals
	*/
	public class Goals {
		public Integer activeMinutes;
		public Integer caloriesOut;
		public Double distance;
		public Integer floors;
		public Integer steps;
		
		public Goals(Integer activeMinutes, Integer caloriesOut, Double distance, Integer floors, Integer steps) {
			this.activeMinutes = activeMinutes;
			this.caloriesOut = caloriesOut;
			this.distance = distance;
			this.floors = floors;
			this.steps = steps;
		}
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-17
	* @description: Inner class for JSON activity summary
	*/
	public class Summary {
		public Integer activeScore;
		public Integer activityCalories;
		public Integer caloriesBMR;
		public Integer caloriesOut;
		public List<Distance> distances;
		public Double elevation;
		public Integer fairlyActiveMinutes;
		public Integer floors;
		public Integer lightlyActiveMinutes;
		public Integer marginalCalories;
		public Integer sedentaryMinutes;
		public Integer steps;
		public Integer veryActiveMinutes;
		
		public Summary(Integer activeScore, Integer activityCalories, Integer caloriesBMR, Integer caloriesOut, List<Distance> distances, Double elevation, Integer fairlyActiveMinutes, Integer floors, Integer lightlyActiveMinutes, Integer marginalCalories, Integer sedentaryMinutes, Integer steps, Integer veryActiveMinutes) {
			this.activeScore = activeScore;
			this.activityCalories = activityCalories;
			this.caloriesBMR = caloriesBMR;
			this.caloriesOut = caloriesOut;
			this.distances = distances.clone();
			this.elevation = elevation;
			this.fairlyActiveMinutes = fairlyActiveMinutes;
			this.floors = floors;
			this.lightlyActiveMinutes = lightlyActiveMinutes;
			this.marginalCalories = marginalCalories;
			this.sedentaryMinutes = sedentaryMinutes;
			this.steps = steps;
			this.veryActiveMinutes = veryActiveMinutes;
		}
		
		public Double getDistance(String activityName) {
			Double dist;
			
			for (Distance d : distances) {
				if (d.activity == activityName) {
					dist = d.distance;
					break;
				}
			}
			
			return dist;
		}
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-17
	* @description: Inner class for JSON activity distances in summary
	*/
	public class Distance {
		public String activity;
		public Double distance;
	}
}