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
	
	public Integer goalSteps {get; private set;}
	public Double goalDistance {get; private set;}
	public Integer todaySteps {get; private set;}
	public Integer todayStepsPercent {get; private set;}
	public Double todayDistance {get; private set;}
	public Integer todayDistancePercent {get; private set;}
	public Integer yesterdaySteps {get; private set;}
	public Integer yesterdayStepsPercent {get; private set;}
	public Double yesterdayDistance {get; private set;}
	public Integer yesterdayDistancePercent {get; private set;}
	public Integer last7StepsTotal {get; private set;}
	public Integer last7StepsAverage {get; private set;}
	public Integer last7StepsPercent {get; private set;}
	public Double last7DistanceTotal {get; private set;}
	public Double last7DistanceAverage {get; private set;}
	public Integer last7DistancePercent {get; private set;}
	public Integer last30StepsTotal {get; private set;}
	public Integer last30StepsAverage {get; private set;}
	public Integer last30StepsPercent {get; private set;}
	public Double last30DistanceTotal {get; private set;}
	public Double last30DistanceAverage {get; private set;}
	public Integer last30DistancePercent {get; private set;}
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
		goalSteps = 0;
		goalDistance = 0;
		todaySteps = 0;
		todayStepsPercent = 0;
		todayDistance = 0;
		todayDistancePercent = 0;
		yesterdaySteps = 0;
		yesterdayStepsPercent = 0;
		yesterdayDistance = 0;
		yesterdayDistancePercent = 0;
		last7StepsTotal = 0;
		last7StepsAverage = 0;
		last7StepsPercent = 0;
		last7DistanceTotal = 0;
		last7DistanceAverage = 0;
		last7DistancePercent = 0;
		last30StepsTotal = 0;
		last30StepsAverage = 0;
		last30StepsPercent = 0;
		last30DistanceTotal = 0;
		last30DistanceAverage = 0;
		last30DistancePercent = 0;
		fbOauth = new FitbitOauth(UserInfo.getUserId());
		
		if (!needsAuthorization) {
			calculateStats();
		}
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
			
			calculateStats();
			
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'Fitbit stats have been updated. Steps: ' + fitbitActivity.Steps__c));
		}
		catch (Exception e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, 'There was an error retrieving the Fitbit stats. Error: ' + e.getMessage()));
		}
		
	}
	
	
	private void calculateStats() {
		Date today = Date.today();
		Date yesterday = today.addDays(-1);
		Date days30 = today.addDays(30);
		Date days7 = today.addDays(7);
		
		goalSteps = fbOauth.getUserData().Fitbit_Goal_Steps__c.intValue();
		goalDistance = fbOauth.getUserData().Fitbit_Goal_Distance__c;
		
		System.debug('@@JOHN@@ goalSteps:' + goalSteps);
		System.debug('@@JOHN@@ goalDistance:' + goalDistance);
		
		for (Fitbit_Activity__c a : [SELECT Id, Active_Score__c, Activity_Calories__c, Calories_BMR__c, Calories_Out__c, Date__c, Elevation__c, Fairly_Active_Minutes__c, Floors__c, Lightly_Active_Distance__c, Lightly_Active_Minutes__c, Logged_Activities_Distance__c, Marginal_Calories__c, Moderately_Active_Distance__c, Sedentary_Active_Distance__c, Sedentary_Minutes__c, Steps__c, Total_Distance__c, Tracker_Distance__c, User__c, Very_Active_Distance__c, Very_Active_Minutes__c FROM Fitbit_Activity__c WHERE User__c =: UserInfo.getUserId() AND Date__c <: days30 ORDER BY Date__c DESC]) {
			
			if (a.Date__c == today) {
				todaySteps = a.Steps__c.intValue();
				todayDistance = a.Total_Distance__c;
			}
			
			if (a.Date__c == yesterday) {
				yesterdaySteps = a.Steps__c.intValue();
				yesterdayDistance = a.Total_Distance__c;
			}
			
			if (a.Date__c < days7) {
				last7StepsTotal += a.Steps__c.intValue();
				last7DistanceTotal += a.Total_Distance__c;
			}
			
			last30StepsTotal += a.Steps__c.intValue();
			last30DistanceTotal += a.Total_Distance__c;
		}
		
		
		todayStepsPercent = ((((Double)todaySteps) / goalSteps) * 100).intValue();
		todayDistancePercent = ((todayDistance / goalDistance) * 100).intValue();
		yesterdayStepsPercent = ((((Double)yesterdaySteps) / goalSteps) * 100).intValue();
		yesterdayDistancePercent = ((yesterdayDistance / goalDistance) * 100).intValue();
		last7StepsAverage = last7StepsTotal / 7;
		last7StepsPercent = ((((Double)last7StepsTotal) / (goalSteps * 7)) * 100).intValue();
		last7DistanceAverage = (last7DistanceTotal / 7).intValue();
		last7DistancePercent = ((last7DistanceTotal / (goalDistance * 7)) * 100).intValue();
		last30StepsAverage = last30StepsTotal / 30;
		last30StepsPercent = ((((Double)last30StepsTotal) / (goalSteps * 30)) * 100).intValue();
		last30DistanceAverage = (last30DistanceTotal / 30).intValue();
		last30DistancePercent = ((last30DistanceTotal / (goalDistance * 30)) * 100).intValue();
	}
}