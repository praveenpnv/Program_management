public class OpportunityTestDataFactory {
    
    public static User createTestUser(Id profileId) {
        String uniqueUsername = 'testuser' + System.currentTimeMillis() + '@example.com';            
        // Create a new User without specifying the Id field
        User testUser = new User(
            ProfileId = profileId,  // Associate with the provided ProfileId
            Username = 'testuser' + Math.random() + '@example.com',  // Ensure uniqueness of the username
            Email = 'testuser@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            LastName = 'User'
        );
        return testUser;  // Do not specify Id field here
    }
    
    public static Opportunity createTestOpportunity(Id userId) {
        // Create and return a new Opportunity for the given User
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            OwnerId = userId,
            Type = 'New Business'
        );
        return testOpportunity;  // No need to specify Id field here either
    }
}