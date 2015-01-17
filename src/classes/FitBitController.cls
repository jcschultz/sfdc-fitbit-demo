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
}