public class CollaboratorEmailService {
    

    @InvocableMethod(label='Get Collaborator Emails')
    public static List<List<String>> getEmails(List<Request> requests) {
        List<String> emails = new List<String>();
        Set<String> ids = new Set<String>();

        if (!requests.isEmpty() && requests[0].inputIdsString != null) {
            String[] collaboratorIds = requests[0].inputIdsString.split(requests[0].delimiter);
            for (String id : collaboratorIds) {
                ids.add(id.trim());
            }
        }
        
        List<String> emailsResult = new List<String>();
        for (User u : [SELECT Email FROM User WHERE Id IN :ids AND Email != null]) {
            emailsResult.add(u.Email);
        }
        for (Contact c : [SELECT Email FROM Contact WHERE Id IN :ids AND Email != null]) {
            emailsResult.add(c.Email);
        }

        List<List<String>> response = new List<List<String>>();
        response.add(emailsResult);
        return response;
    }
    
    public class Request {
        @InvocableVariable(label='Collaborator IDs' description='The string of IDs to process.')
        public String inputIdsString;

        @InvocableVariable(label='Delimiter' description='The character to split the text by (e.g., a semicolon).' required=true)
        public String delimiter;
    }
}