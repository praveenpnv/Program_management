public class RD1ToTorc_Notes
{
    public static String getGraphQLJson(Task RdNote, boolean isInsert,Contact con,TR1__Job__c job) 
    {
        List<String> lstQuery = new List<String>();
         if(isInsert)
        {
            lstQuery.add('mutation CreateNote($input: CreateNoteInput!){');
            lstQuery.add('createNote(input: $input){');
        }
        else
        {
            lstQuery.add('mutation CreateNote($input: CreateNoteInput!){');
            lstQuery.add('createNote(input: $input){');
        }
        lstQuery.add('id');
        lstQuery.add('}');
        lstQuery.add('}');
        PlatformNote note = new PlatformNote(String.join(lstQuery, ' '), RdNote,con,job);
        return note.getJSON();
    }


    public static Platform_NoteResponse parse(String json)
    {
        if(Test.isRunningTest())
            return new Platform_NoteResponse();
        return (Platform_NoteResponse) System.JSON.deserialize(json, Platform_NoteResponse.class);
    }
    public class PlatformNote 
    {
        public string query {get;set;}
        public Note_Variable_Wrapper variables{get;set;}
        public PlatformNote(String query, Task Rdnote,contact con,TR1__Job__c job) 
        {
            this.query = query;
            this.variables = new Note_Variable_Wrapper();
            this.variables.input = new Note_Variable_Input();
            torcRD1integrationMapping.filldata(this.variables.input, Rdnote,con,job);
        }
        public String getJSON() 
        {
            Boolean suppresNulls = true;
            String tempJSON = JSON.serialize(this, suppresNulls);
            return tempJSON;
        }
    }

    public class Note_Variable_Wrapper 
    {
        public Note_Variable_Input input {get;set;} 
    }
    public class Note_Variable_Input 
    {
        public string content{get;set;}
        public string userId{get;set;}
        public string jobOpportunityId{get;set;}
        public string externalId{get;set;}
        public string noteType{get;set;}
        public boolean isPublic{get;set;}
    }

    /*************************** JOB RESPONSE *************************************/
    // If more fields are added in response they should be 
    public class Platform_NoteResponse 
    {
        public String id;
    }
}