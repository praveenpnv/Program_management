@IsTest
public class ProjectPlatformControllerTest {

    @TestSetup
    static void setupData() {

        // Create User
        Profile p = [SELECT Id FROM Profile LIMIT 1];

        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert u;

        // Program
        Program__c prog = new Program__c(
            Name = 'Test Program',
            Type__c = 'Internal',
            Status__c = 'Active',
            Program_Owner__c = u.Id
        );
        insert prog;

        // Project
        Project__c proj = new Project__c(
            Name = 'Test Project',
            Status__c = 'On going',
            Stage__c = 'Execution',
            OwnerId = u.Id,
            Program__c = prog.Id,
            Project_Type__c = 'Standard'
        );
        insert proj;

        // Feature
        Feature__c feat = new Feature__c(
            Name = 'Test Feature',
            Project__c = proj.Id,
            Status__c = 'Open'
        );
        insert feat;

        // Requirement (✅ FIXED)
        Requirement__c req = new Requirement__c(
            Name = 'Test Requirement',
            Status__c = 'Draft',
            Feature__c = feat.Id,
            Project__c = proj.Id,
            Requestor__c = 'Test User' // 🔥 REQUIRED FIELD
        );
        insert req;

        // Story
        Story__c story = new Story__c(
            Name = 'Test Story',
            Status__c = 'In Progress',
            Feature__c = feat.Id
        );
        insert story;

        // Junction
        insert new Story_Project__c(
            Story__c = story.Id,
            Project__c = proj.Id
        );

        // Release
        Release__c rel = new Release__c(
            Name = 'Test Release',
            Project__c = proj.Id,
            Stage__c = 'Planning',
            Go_Live_Date__c = Date.today().addDays(5)
        );
        insert rel;
    }

    // ───────── PROGRAM ─────────
    @IsTest
    static void testGetPrograms() {
        Test.startTest();
        List<ProjectPlatformController.ProgramWrapper> result =
            ProjectPlatformController.getPrograms();
        Test.stopTest();

        System.assert(result.size() > 0);
    }

    // ───────── PROJECT ─────────
    @IsTest
    static void testGetProjects() {
        Test.startTest();
        List<ProjectPlatformController.ProjectWrapper> projects =
            ProjectPlatformController.getProjects();
        Test.stopTest();

        System.assert(projects.size() > 0);
    }

    @IsTest
    static void testSaveProject() {
        Map<String, Object> data = new Map<String, Object>{
            'name' => 'New Project',
            'status' => 'On going',
            'stage' => 'Execution',
            'projectType' => 'Standard'
        };

        Test.startTest();
        Id id = ProjectPlatformController.saveProject(JSON.serialize(data));
        Test.stopTest();

        System.assertNotEquals(null, id);
    }

    // ───────── FEATURE ─────────
    @IsTest
    static void testFeatures() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        List<Feature__c> feats =
            ProjectPlatformController.getFeaturesByProject(new List<Id>{proj.Id});
        Test.stopTest();

        System.assert(feats.size() > 0);
    }

    // ───────── REQUIREMENT ─────────
    @IsTest
    static void testSaveRequirement() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Feature__c feat = [SELECT Id FROM Feature__c LIMIT 1];

        Map<String, Object> data = new Map<String, Object>{
            'name' => 'Req Test',
            'status' => 'Draft',
            'projectId' => proj.Id,
            'requestor' => 'Test User',
            'featureId' => feat.Id
                
        };

        Test.startTest();
        Id reqId =
            ProjectPlatformController.saveRequirement(JSON.serialize(data));
        Test.stopTest();

        System.assertNotEquals(null, reqId);
    }

    // ───────── STORY ─────────
    @IsTest
    static void testSaveStory() {
        Feature__c feat = [SELECT Id FROM Feature__c LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Map<String, Object> data = new Map<String, Object>{
            'name' => 'Story Test',
            'status' => 'In Progress',
            'featureId' => feat.Id,
            'projectIds' => new List<String>{proj.Id}
        };

        Test.startTest();
        Id storyId =
            ProjectPlatformController.saveStory(JSON.serialize(data));
        Test.stopTest();

        System.assertNotEquals(null, storyId);
    }

    @IsTest
    static void testGetStoriesByProject() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        List<Story__c> stories =
            ProjectPlatformController.getStoriesByProject(proj.Id);
        Test.stopTest();

        System.assert(stories.size() > 0);
    }

    // ───────── STORY LINK ─────────
    @IsTest
    static void testLinkStories() {
        List<Story__c> stories = [SELECT Id FROM Story__c LIMIT 2];

        if (stories.size() < 2) return;

        Test.startTest();
        Story_Link__c link =
            ProjectPlatformController.linkStories(
                stories[0].Id,
                stories[1].Id,
                'Relates To'
            );
        Test.stopTest();

        System.assertNotEquals(null, link);
    }

    // ───────── RELEASE ─────────
    @IsTest
    static void testSaveRelease() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Map<String, Object> data = new Map<String, Object>{
            'name' => 'Rel Test',
            'projectId' => proj.Id,
            'stage' => 'Planning'
        };

        Test.startTest();
        Id relId =
            ProjectPlatformController.saveRelease(JSON.serialize(data));
        Test.stopTest();

        System.assertNotEquals(null, relId);
    }

    // ───────── DASHBOARD ─────────
    @IsTest
    static void testDashboard() {
        Test.startTest();
        ProjectPlatformController.DashboardMetrics m =
            ProjectPlatformController.getDashboardMetrics();
        Test.stopTest();

        System.assertNotEquals(null, m);
    }

    // ───────── ACTIVITY ─────────
    @IsTest
    static void testActivities() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        Id taskId =
            ProjectPlatformController.addActivity(proj.Id, 'Test Comment');

        List<Task> tasks =
            ProjectPlatformController.getActivitiesForRecord(proj.Id);
        Test.stopTest();

        System.assertNotEquals(null, taskId);
        System.assert(tasks.size() > 0);
    }
}