global without sharing class InsertSkills {

	global  class Parameter {
		@InvocableVariable
		global List<ATSExtractedCandidateSkill__c> extractedSkills;
	}

	@InvocableMethod(Label='Insert skills and handle duplicates')
	global static void processSkills(List<Parameter> parameters) {
		List<ATSExtractedCandidateSkill__c> allExtractedToInsert  = new List<ATSExtractedCandidateSkill__c>();
		//List<SObject> allNormalizedToInsert = new List<SObject>();

		for (Parameter parameter : parameters) {
			allExtractedToInsert.addAll(parameter.extractedSkills);
		}
        
          if (!allExtractedToInsert.isEmpty()) {
            // Use Database.insert with allOrNone = false
            Database.SaveResult[] results = Database.insert(allExtractedToInsert, false);
			System.debug('inserted skills results:' + results);
            // Loop through the results to check for errors
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    // Handle the error for each record that failed to insert
                    Database.Error error = results[i].getErrors()[0];
                    System.debug('Failed to insert skill: ' + allExtractedToInsert[i].Name + ', Error: ' + error.getMessage());
                }
            }
        }
  /*      
		//Database.DMLOptions dml = new Database.DMLOptions();
		if (allExtractedToInsert.size() != 0) { Database.insert(allExtractedToInsert,false) ; }*/
	}
}