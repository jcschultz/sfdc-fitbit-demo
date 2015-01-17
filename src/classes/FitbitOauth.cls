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
	* @description: Retrieves the fitbit api custom setting info
	* @return: void
	*/
	private void getFitbitSettings() {
		try {
			apiSettings = [SELECT Authorize_URL__c, Client_Key__c, Client_Secret__c, Temporary_Credentials_URL__c, Token_Credentials_URL__c FROM Fitbit_API__c LIMIT 1];
		}
		catch (Exception e) {
			throw new FitbitOauthException('The Fitbit OAuth Service has not yet been created. Your System Administrator must first set that up.');
		}
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Retrieves the token and token secret for the user
	* @param: userId - String of the user id for the user whose token you wish to retrieve
	* @return: void
	*/
	private void getUserToken(String userId) {
		userData = [SELECT Id, Fitbit_Oauth_Token__c, Fitbit_Oauth_Token_Secret__c FROM User WHERE Id =: userId LIMIT 1];
	}
	
	
	public class FitbitOauthException extends Exception {}
}