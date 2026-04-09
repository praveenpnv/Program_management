@IsTest
public class ManagerTeamControllerTest {

    private static User createUser(String alias, String profileName, String opco) {
        Id currentUserId = UserInfo.getUserId();
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User u = new User(
            FirstName = alias,
            LastName  = 'Test',
            Alias     = alias.left(8),
            Email     = alias + '@test.com',
            Username  = alias + Datetime.now().getTime() + '@test.com',
            CommunityNickname = alias + String.valueOf(Math.random()).replace('.', ''),
            TimeZoneSidKey    = 'Asia/Kolkata',
            Dashboard_Role__c = 'Sales (Account Manager)',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId         = p.Id,
            Opco__c           = opco
        );
        insert u;
        return u;
    }
    private static Manager_Team_Member__c createManagerTeamMember(string type,Id userId){
        Id currentUserId = UserInfo.getUserId();
        Manager_Team_Member__c mtm = new Manager_Team_Member__c();
        mtm.Recruiter_Manager__c = currentUserId;
        mtm.Manager__c = userId;
        mtm.Role__c = type;
        mtm.Active__c = true;
        mtm.Assignment_Key__c = currentUserId + '_' + userId;
        insert mtm;
        return mtm;
    }

    @IsTest
    static void testGetAvailableUsers_AccountManager() {
        String opco = 'UK';
        User rm = createUser('rmAM', 'Sales (Account Manager)', opco);
        System.runAs(rm) {
            Test.startTest();
            List<ManagerTeamController.UserDTO> result = ManagerTeamController.getAvailableUsers('Account Manager');
            Test.stopTest();

            System.assertNotEquals(0, result.size(), 'Should return at least one Account Manager');
        }
    }

    @IsTest
    static void testGetAvailableUsers_Recruiter() {
        String opco = 'India';
        User recruiter = createUser('recruiter1', 'Recruiter', opco);

        System.runAs(recruiter) {
            Test.startTest();
            List<ManagerTeamController.UserDTO> result = ManagerTeamController.getAvailableUsers('Recruiter');
            Test.stopTest();

            System.assertNotEquals(1, result.size(), 'Should return Recruiters');
        }
    }
    @IsTest
    static void testGetAvailableUsers_AllUsers() {
        String opco = 'India';
        User recruiter = createUser('recruiter1', 'Recruiter', opco);

        System.runAs(recruiter) {
            Test.startTest();
            List<ManagerTeamController.UserDTO> result = ManagerTeamController.getAvailableUsers('All');
            Test.stopTest();

            System.assertNotEquals(0, result.size(), 'Should return Recruiters');
        }
    }

    @IsTest
    static void testAddAndRemoveFromTeam() {
        String opco = 'UK';
        Id currentUserId = UserInfo.getUserId();
        User rm = createUser('rm', 'Sales (Account Manager)', opco);
        User recruiter = createUser('recruiter2', 'Recruiter', opco);
        System.runAs(rm) {
            Test.startTest();
            ManagerTeamController.addToTeam(recruiter.Id, 'Recruiter',currentUserId);
            List<Manager_Team_Member__c> mtms = [
                SELECT Id, Manager__c, Recruiter_Manager__c, Active__c
                FROM Manager_Team_Member__c
                WHERE Manager__c = :recruiter.Id
                AND Recruiter_Manager__c =:currentUserId
                AND Role__c = 'Recruiter'
            ];
            System.assertEquals(1, mtms.size(), 'Recruiter should be added to team');

            ManagerTeamController.removeFromTeam(recruiter.Id, 'Recruiter',currentUserId);
            List<Manager_Team_Member__c> mtmsAfter = [
                SELECT Id FROM Manager_Team_Member__c
                WHERE Manager__c = :recruiter.Id
                AND Recruiter_Manager__c = :currentUserId
                AND Role__c = 'Recruiter'
            ];
            System.assertEquals(0, mtmsAfter.size(), 'Recruiter should be removed from team');
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetTeamMembers() {
        String opco = 'India';
        Id currentUserId = UserInfo.getUserId();
       // User rm = createUser('rmTeam', 'Sales (Account Manager)', opco);
        //User recruiter = createUser('recruiter3', 'Recruiter', opco);
        Manager_Team_Member__c mtm = createManagerTeamMember('Recruiter',currentUserId);
            Test.startTest();
            List<ManagerTeamController.UserDTO> result = ManagerTeamController.getTeamMembers('Recruiter',currentUserId);
            List<ManagerTeamController.UserDTO> recurTeamMember = ManagerTeamController.getRecursiveTeamMembers(currentUserId);
            Test.stopTest();

            System.assertEquals(1, result.size(), 'Failed');
    }
    
    @IsTest
    static void testRemoveFromTeam_NotExists() {
        Id currentUserId = UserInfo.getUserId();
        String opco = 'India';
        User rm = createUser('rmRem', 'Sales (Account Manager)', opco);
        User recruiter = createUser('recruiterRem', 'Recruiter', opco);

        System.runAs(rm) {
            Test.startTest();
            Boolean exceptionThrown = false;
            try {
                ManagerTeamController.removeFromTeam(recruiter.Id, 'Recruiter',currentUserId);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            Test.stopTest();
            System.assert(exceptionThrown, 'Should throw exception if recruiter is not in team');
        }
    }
}