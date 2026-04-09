public with sharing class RegionCtrl {
    
    /**
     * Get all active territories from Enhanced Territory Management
     * Using only standard Territory2 fields
     */
    @AuraEnabled(cacheable=true)
    public static List<TerritoryWrapper> getRegions() {
        try {
            List<Territory2> territories = [
                SELECT Id, Name, DeveloperName, Description
                FROM Territory2
                WHERE Territory2Model.State = 'Active'
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
            ];
            
            List<TerritoryWrapper> wrappers = new List<TerritoryWrapper>();
            for (Territory2 terr : territories) {
                TerritoryWrapper wrapper = new TerritoryWrapper();
                wrapper.Id = terr.Id;
                wrapper.Name = terr.Name;
                wrapper.Status = 'Active';
                wrapper.TerritoryId = terr.Id;
                wrapper.Color = getColorForTerritory(terr.Name);
                wrapper.GeoJSONBoundary = getGeoJSONForTerritory(terr.Name);
                wrappers.add(wrapper);
            }
            
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching territories: ' + e.getMessage());
        }
    }
    
    /**
     * Get accounts or opportunities assigned to a territory
     */
    @AuraEnabled(cacheable=true)
    public static List<JobWrapper> getJobsByRegion(Id regionId) {
        try {
            // Get account IDs assigned to this territory
            Set<Id> accountIds = new Set<Id>();
            for (ObjectTerritory2Association ota : [
                SELECT ObjectId 
                FROM ObjectTerritory2Association
                WHERE Territory2Id = :regionId
                AND IsDeleted = false
            ]) {
                accountIds.add(ota.ObjectId);
            }
            
            // Query accounts with billing address
            List<Account> accounts = [
                SELECT Id, Name, BillingStreet, BillingCity, BillingState,
                       BillingLatitude, BillingLongitude, Type, Industry
                FROM Account
                WHERE Id IN :accountIds
                AND BillingLatitude != null
                AND BillingLongitude != null
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
                LIMIT 100
            ];
            
            List<JobWrapper> wrappers = new List<JobWrapper>();
            for (Account acc : accounts) {
                JobWrapper wrapper = new JobWrapper();
                wrapper.Id = acc.Id;
                wrapper.Name = acc.Name;
                wrapper.Status = acc.Type != null ? acc.Type : 'Active';
                wrapper.Priority = 'Normal';
                wrapper.Latitude = acc.BillingLatitude;
                wrapper.Longitude = acc.BillingLongitude;
                wrapper.IsOverdue = false;
                wrapper.Account = new AccountReference(acc.Name);
                wrappers.add(wrapper);
            }
            
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching jobs: ' + e.getMessage());
        }
    }
    
    /**
     * Get territory KPIs
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRegionKPIs(Id regionId) {
        try {
            Integer totalAccounts = [
                SELECT COUNT()
                FROM ObjectTerritory2Association
                WHERE Territory2Id = :regionId
                AND IsDeleted = false
            ];
            
            Map<String, Object> kpis = new Map<String, Object>();
            kpis.put('total', totalAccounts);
            kpis.put('completed', 0);
            kpis.put('inProgress', 0);
            kpis.put('overdue', 0);
            
            return kpis;
        } catch (Exception e) {
            throw new AuraHandledException('Error calculating KPIs: ' + e.getMessage());
        }
    }
    
    /**
     * Reassign accounts to different territory
     */
    @AuraEnabled
    public static String reassignJobs(List<Id> accountIds, Id newRegionId) {
        try {
            List<ObjectTerritory2Association> toDelete = [
                SELECT Id
                FROM ObjectTerritory2Association
                WHERE ObjectId IN :accountIds
            ];
            delete toDelete;
            
            List<ObjectTerritory2Association> toInsert = new List<ObjectTerritory2Association>();
            for (Id accountId : accountIds) {
                ObjectTerritory2Association ota = new ObjectTerritory2Association();
                ota.ObjectId = accountId;
                ota.Territory2Id = newRegionId;
                ota.AssociationCause = 'Territory2Manual';
                toInsert.add(ota);
            }
            insert toInsert;
            
            return 'Successfully reassigned ' + accountIds.size() + ' accounts';
        } catch (Exception e) {
            throw new AuraHandledException('Error reassigning: ' + e.getMessage());
        }
    }
    
    /**
     * Helper: Return hardcoded GeoJSON based on territory name
     * TODO: Replace with custom field once added to Territory2
     */
    private static String getGeoJSONForTerritory(String territoryName) {
        Map<String, String> geoJsonMap = new Map<String, String>();
        
        // Northern California - San Francisco Bay Area
        geoJsonMap.put('Northern California', 
            '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-122.5155,37.8103],[-122.3549,37.8103],[-122.3549,37.7034],[-122.5155,37.7034],[-122.5155,37.8103]]]}}');
        
        // Southern California - Los Angeles
        geoJsonMap.put('Southern California', 
            '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-118.6682,34.1617],[-118.1553,34.1617],[-118.1553,33.7037],[-118.6682,33.7037],[-118.6682,34.1617]]]}}');
        
        // Texas - Austin
        geoJsonMap.put('Texas', 
            '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-97.9383,30.5168],[-97.5698,30.5168],[-97.5698,30.0986],[-97.9383,30.0986],[-97.9383,30.5168]]]}}');
        
        // New York
        geoJsonMap.put('New York', 
            '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-74.0479,40.9176],[-73.7004,40.9176],[-73.7004,40.4774],[-74.0479,40.4774],[-74.0479,40.9176]]]}}');
        
        // Chicago
        geoJsonMap.put('Chicago', 
            '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-87.9401,42.0231],[-87.5240,42.0231],[-87.5240,41.6445],[-87.9401,41.6445],[-87.9401,42.0231]]]}}');
        
        // Return matching GeoJSON or default square
        if (geoJsonMap.containsKey(territoryName)) {
            return geoJsonMap.get(territoryName);
        }
        
        // Default: small square for unknown territories
        return '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-100,40],[-99,40],[-99,39],[-100,39],[-100,40]]]}}';
    }
    
    /**
     * Helper: Assign colors based on territory name
     */
    private static String getColorForTerritory(String territoryName) {
        Map<String, String> colorMap = new Map<String, String>{
            'Northern California' => '#FF6B6B',
            'Southern California' => '#4ECDC4',
            'Texas' => '#95E1D3',
            'New York' => '#FFE66D',
            'Chicago' => '#A8E6CF'
        };
        
        return colorMap.containsKey(territoryName) ? colorMap.get(territoryName) : '#3388ff';
    }
    
    // Wrapper classes
    public class TerritoryWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String GeoJSONBoundary;
        @AuraEnabled public String Color;
        @AuraEnabled public String Status;
        @AuraEnabled public String TerritoryId;
    }
    
    public class JobWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Status;
        @AuraEnabled public String Priority;
        @AuraEnabled public Decimal Latitude;
        @AuraEnabled public Decimal Longitude;
        @AuraEnabled public Boolean IsOverdue;
        @AuraEnabled public AccountReference Account;
    }
    
    public class AccountReference {
        @AuraEnabled public String Name;
        public AccountReference(String name) { this.Name = name; }
    }
}