/*
 * @author John Schultz, salesforce.com
 * @date January 16, 2015
 * @description Controller for handling the callback and tokens from fitbit oauth process
 * @log:
 *	-----------------------------------------------------------------------------
 *	Developer			Date		Description
 *	-----------------------------------------------------------------------------
 *	John Schultz		2015-01-16	Newly created
 */

public class FitbitCallbackController {
	
	private FitbitOauth fbOauth;
	private Map<String, String> pageParams;
	
	public FitbitCallbackController() {
		pageParams = ApexPages.currentPage().getParameters();
		
		fbOauth = new FitbitOauth(UserInfo.getUserId());
	}
	
	/**
	* @author: John Schultz
	* @date: 2015-01-16
	* @description: Processes temp tokens, gets real tokens, and redirects to fitbit page
	* @return: pRef - Page reference redirect
	*/
	public PageReference processTokens() {
		
		fbOauth.requestTokens(pageParams.get('oauth_token'), pageParams.get('oauth_verifier'));
		
		PageReference pRef = new PageReference('/apex/Fitbit');
		pRef.setRedirect(true);
		return pRef;
	}
}