/*
 * @author John Schultz, salesforce.com
 * @date January 18, 2015
 * @description Batch to grab the current or previous day's fitbit activity on an hourly basis.
 *				Run using: System.schedule('Fitbit Batch', '0 0 * * * ?', new FitbitBatch());
 * @log:
 *	-----------------------------------------------------------------------------
 *	Developer			Date		Description
 *	-----------------------------------------------------------------------------
 *	John Schultz		2015-01-18	Newly created
 */

global class FitbitBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable {
	
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new FitbitBatch(), 1);
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id, Fitbit_Oauth_Token__c, Fitbit_Oauth_Token_Secret__c FROM User WHERE IsActive = true';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<User> scope) {
   		if (scope[0].Fitbit_Oauth_Token__c != null && scope[0].Fitbit_Oauth_Token_Secret__c != null) {
   			FitbitOauth fbOauth = new FitbitOauth(scope[0].Id);
   			
   			DateTime rightNow = DateTime.now();
   			Date myDate = Date.today();
   			
   			if (rightNow.hour() < 2) {
   				myDate.addDays(-1);
   			}
   			
   			
   			String day = String.valueOf(myDate.day());
   			String month = String.valueOf(myDate.month());
   			String year = String.valueOf(myDate.year());
   			
   			if (day.length() < 2) {
   				day = '0' + day;
   			}
   			
   			if (month.length() < 2) {
   				month = '0' + month;
   			}
   			
   			fbOauth.getActivities(year + '-' + month + '-' + day);
   		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}