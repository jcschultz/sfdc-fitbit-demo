/*
 * @author John Schultz, salesforce.com
 * @date January 19, 2015
 * @description Tests for fitbit classes and controllers
 * @log:
 *	-----------------------------------------------------------------------------
 *	Developer			Date		Description
 *	-----------------------------------------------------------------------------
 *	John Schultz		2015-01-19	Newly created
 */

@isTest
public class FitbitTests {
	private static Fitbit_API__c api;
	private static User admin;
	private static User testUser;
	static {
		// create users
		admin = new User(
			ProfileId = [Select ID From Profile Where Name = 'System Administrator' Limit 1].Id
			, LastName = 'testadmin'
			, Email = 'admin@fitbit.app.test.com'
			, Username = 'admin@fitbit.app.test.com'
			, Alias = 'testadmi'
			, CompanyName = 'Salesforce'
			, TimeZoneSidKey='America/Chicago'
			, EmailEncodingKey='UTF-8'
			, LanguageLocaleKey='en_US' 
			, LocaleSidKey='en_US'
		);
		testUser = new User(
			ProfileId = [Select ID From Profile Where Name = 'Standard User Custom' Limit 1].Id
			, LastName = 'testuser'
			, Email = 'user@fitbit.app.test.com'
			, Username = 'user@fitbit.app.test.com'
			, Alias = 'testuser'
			, CompanyName = 'Salesforce'
			, TimeZoneSidKey='America/Chicago'
			, EmailEncodingKey='UTF-8'
			, LanguageLocaleKey='en_US' 
			, LocaleSidKey='en_US'
		);
		insert new List<User>{admin, testUser};
		
		// create custom setting
		api = new Fitbit_API__c(
			Authorize_URL__c = 'http://www.authurl.com'
			, Client_Key__c = '123456abcdef'
			, Client_Secret__c = 'abcdef123456'
			, Get_Activities_URL__c = 'http://www.acturl.com'
			, Temporary_Credentials_URL__c = 'http://www.tempcredurl.com'
			, Token_Credentials_URL__c = 'http://www.tokencredurl.com'
			, Name = 'testingApi'
		);
		insert api;
	}
	
	static testMethod void testUserAuth1() {
		
		System.runAs(testUser) {
			Test.startTest();
			PageReference dashboard = Page.Fitbit;
			Test.setCurrentPage(dashboard);
			Test.setMock(HttpCalloutMock.class, new FitbitMockCallout());
			
			FitBitController fbCon = new FitBitController();
			
			System.assert(fbCon.needsAuthorization);
			
			PageReference authRef = fbCon.authorize();
			System.assertEquals(api.Authorize_URL__c + '?oauth_token=c5a8b2ff2a20524381083b1fe172fdc1', authRef.getUrl());
			Test.stopTest();
		}
		
	}
	
	static testMethod void testUserAuth2() {
		
		System.runAs(testUser) {
			Test.startTest();
			Test.setMock(HttpCalloutMock.class, new FitbitMockCallout());
			
			PageReference callback = Page.FitbitCallback;
			Test.setCurrentPage(callback);
			ApexPages.currentPage().getParameters().put('oauth_token', 'c5a8b2ff2a20524381083b1fe172fdc1');
			ApexPages.currentPage().getParameters().put('oauth_verifier', 'verify123');
			FitbitCallbackController cbCon = new FitbitCallbackController();
			
			PageReference dashReturn = cbCon.processTokens();
			
			Test.stopTest();
		}
		
		User testU = [SELECT Id, Fitbit_Oauth_Token__c, Fitbit_Oauth_Token_Secret__c, Fitbit_Goal_Active_Minutes__c, Fitbit_Goal_Calories_Out__c, Fitbit_Goal_Distance__c, Fitbit_Goal_Floors__c, Fitbit_Goal_Steps__c FROM User WHERE Id =: testUser.Id];
		
		System.assertEquals('8d3221fb072f31b5ef1b3bcfc5d8a27a', testU.Fitbit_Oauth_Token__c);
		System.assertEquals('894fa2bec6f6acc570b80135218656f5', testU.Fitbit_Oauth_Token_Secret__c);
		
	}
	
	static testMethod void testGetActivity() {
		testUser.Fitbit_Oauth_Token__c = '8d3221fb072f31b5ef1b3bcfc5d8a27a';
		testUser.Fitbit_Oauth_Token_Secret__c = '894fa2bec6f6acc570b80135218656f5';
		update testUser;
		
		System.runAs(testUser) {
			Test.startTest();
			Test.setMock(HttpCalloutMock.class, new FitbitMockCallout());
			PageReference dashboard = Page.Fitbit;
			Test.setCurrentPage(dashboard);
			FitBitController fbCon = new FitBitController();
			
			System.assertNotEquals(true, fbCon.needsAuthorization);
			
			fbCon.fetchToday();
			System.assertEquals(500, fbCon.todaySteps);
			Test.stopTest();
		}
	}
}