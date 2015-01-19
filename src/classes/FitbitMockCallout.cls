@isTest
public class FitbitMockCallout implements HttpCalloutMock {

	public HTTPResponse respond(HTTPRequest req) {
		HttpResponse res;
		
		if (req.getEndpoint() == 'http://www.tempcredurl.com') {
			res = temporaryCreds(req);
		}
		else if (req.getEndpoint() == 'http://www.tokencredurl.com') {
			res = tokenCreds(req);
		}
		else if (req.getEndpoint() == 'http://www.acturl.com') {
			res = activities(req);
		}
		
		return res;
	}
	
	private HttpResponse temporaryCreds(HttpRequest req) {
		// Create a fake response
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		res.setBody('oauth_token=c5a8b2ff2a20524381083b1fe172fdc1&oauth_token_secret=8508e7c450fc2462ae4932fa63c35b30&oauth_callback_confirmed=true');
		res.setStatusCode(200);
		return res;
	}
	
	private HttpResponse tokenCreds(HttpRequest req) {
		// Create a fake response
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		res.setBody('oauth_token=8d3221fb072f31b5ef1b3bcfc5d8a27a&oauth_token_secret=894fa2bec6f6acc570b80135218656f5&encoded_user_id=228TQ4');
		res.setStatusCode(200);
		return res;
	}
	
	private HttpResponse activities(HttpRequest req) {
		// Create a fake response
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		res.setBody('{"activities":[], "goals":{"caloriesOut":2826, "distance":8.05, "floors":150, "steps":10000 }, "summary":{"activityCalories":230, "caloriesOut":1343, "distances":[{"activity":"tracker", "distance":1.32}, {"activity":"loggedActivities", "distance":0}, {"activity":"total","distance":1.32}, {"activity":"veryActive", "distance":0.51}, {"activity":"moderatelyActive", "distance":0.51}, {"activity":"lightlyActive", "distance":0.51}, {"activity":"sedentaryActive", "distance":0.51} ], "fairlyActiveMinutes":0, "lightlyActiveMinutes":0, "marginalCalories":200, "sedentaryMinutes":1166, "steps":500, "veryActiveMinutes":0 } }');
		res.setStatusCode(200);
		return res;
	}

}