/*
 * @author John Schultz, salesforce.com
 * @date January 15, 2015
 * @description Controller for FitBit page
 * @log:
 *	-----------------------------------------------------------------------------
 *	Developer			Date		Description
 *	-----------------------------------------------------------------------------
 *	John Schultz		2015-01-15	Newly created
 */

public class FitBitController {
	
	private FitbitOauth fbOauth;
	
	public String activityId {get; private set;}
	public Fitbit_Activity__c fitbitActivity {get; private set;}
	public Boolean needsAuthorization {
		get {
			// if the user's oauth token or oauth token secret are blank, the user needs to authenticate with fitbit.
			return (String.isBlank(fbOauth.getUserData().Fitbit_Oauth_Token__c) || String.isBlank(fbOauth.getUserData().Fitbit_Oauth_Token_Secret__c));
		}
		private set;
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Controller method
	*/
	public FitBitController() {
		fbOauth = new FitbitOauth(UserInfo.getUserId());
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Redirects the user to the fitbit authorization page
	* @return: pRef - PageReference url with fitbit api specific parameters
	*/
	public PageReference authorize() {
		return fbOauth.getAuthorization();
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-17
	* @description: Fetches today's fitbit activity record from fitbit's api
	* @return: void
	*/
	public void fetchToday() {
		Date today = Date.today();
		String day = String.valueOf(today.day());
		String month = String.valueOf(today.month());
		String year = String.valueOf(today.year());
		
		if (day.length() < 2) {
			day = '0' + day;
		}
		
		if (month.length() < 2) {
			month = '0' + month;
		}
		
		try {
			activityId = fbOauth.getActivities(year + '-' + month + '-' + day);
			
			fitbitActivity = [SELECT Id, Active_Score__c, Activity_Calories__c, Calories_BMR__c, Calories_Out__c, Date__c, Elevation__c, Fairly_Active_Minutes__c, Floors__c, Lightly_Active_Distance__c, Lightly_Active_Minutes__c, Logged_Activities_Distance__c, Marginal_Calories__c, Moderately_Active_Distance__c, Sedentary_Active_Distance__c, Sedentary_Minutes__c, Steps__c, Total_Distance__c, Tracker_Distance__c, User__c, Very_Active_Distance__c, Very_Active_Minutes__c FROM Fitbit_Activity__c WHERE User__c =: UserInfo.getUserId() AND Id =: activityId];
			
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'Fitbit stats have been updated. Steps: ' + fitbitActivity.Steps__c));
		}
		catch (Exception e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, 'There was an error retrieving the Fitbit stats. Error: ' + e.getMessage()));
		}
		
	}
}