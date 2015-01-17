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
	
	public FitBitController() {
		fbOauth = new FitbitOauth(UserInfo.getUserId());
	}
}