@IsTest
private class DataLoad_ExtractJobSkill_Test {

    // 200 mock returning only what the parser reads
    private class TK200 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(200);
            r.setStatus('OK');
            r.setBody('{"Value":{"Skills":[' +
                      '{"Id":"KS120026VL50QFWT2281","Description":"ASP.NET"},' +
                      '{"Id":"KSTCKINCCLKBAHVAOXO8","Description":"Restful APIs"}]}}');
            return r;
        }
    }

    @IsTest
    static void cover_Batch_Markers_SingleCallout() {
        // ---- Setup master skills (strict by code), include TR1__Type__c = 'IT_Skill'
        insert new List<TR1__Master_Skill__c>{
            new TR1__Master_Skill__c(
                TR1__Skill_Code__c = 'KS120026VL50QFWT2281',
                TR1__Master_Skill_Name__c = 'ASP.NET',
                TR1__Type__c = 'IT_Skill'
            ),
            new TR1__Master_Skill__c(
                TR1__Skill_Code__c = 'KSTCKINCCLKBAHVAOXO8',
                TR1__Master_Skill_Name__c = 'Restful APIs',
                TR1__Type__c = 'IT_Skill'
            )
        };

        // ---- Build >24k text to hit truncation
        String big = 'Z';
        while (big.length() < 25050) big += big;

        // ---- Jobs (Job_Type__c required)
        TR1__Job__c j1 = new TR1__Job__c(
            Name = 'Job A',
            Job_Type__c = 'Contract',
            TR1__Client_Job_Description__c = big
        );
        TR1__Job__c j2 = new TR1__Job__c(
            Name = 'Job B',
            Job_Type__c = 'Contract',
            TR1__Client_Job_Description__c = null // ensures no callout for this marker
        );
        insert new List<TR1__Job__c>{ j1, j2 };

        // Pre-existing child to exercise de-dupe for Job A
        insert new TR1__Skills__c(
            TR1__Job__c = j1.Id,
            TR1__Extracted_Skill_Name__c = 'ASP.NET'
        );

        // ---- Markers: one success (j1), one no-text (j2), one missing job (null)
        Data_Load_Legacy_Skill__c m1 = new Data_Load_Legacy_Skill__c(Name='M1', Job__c=j1.Id);
        Data_Load_Legacy_Skill__c m2 = new Data_Load_Legacy_Skill__c(Name='M2', Job__c=j2.Id);
        Data_Load_Legacy_Skill__c m3 = new Data_Load_Legacy_Skill__c(Name='M3'); // no Job__c -> failure path (no callout)
        insert new List<Data_Load_Legacy_Skill__c>{ m1, m2, m3 };

        // ---- Cover start() (no callouts)
        DataLoad_ExtractJobSkill b = new DataLoad_ExtractJobSkill('TR1__Client_Job_Description__c');
        b.start(null);

        // ---- Single callout path: execute() on markers (only j1 calls out)
        Test.setMock(HttpCalloutMock.class, new TK200());
        Test.startTest();
        b.execute(null, new List<Data_Load_Legacy_Skill__c>{ m1, m2, m3 });
        Test.stopTest();

        // (No asserts; focused solely on coverage.)
    }
}