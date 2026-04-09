/**
 * Enhanced SimplePOCController with Regional Intelligence
 * FIXED: Removed SOQL queries from loops to avoid governor limits
 */
public with sharing class SimplePOCController {
    
    /**
     * Get all active regions with intelligence metrics
     * OPTIMIZED: Uses aggregate queries instead of loops
     */
    @AuraEnabled(cacheable=true)
    public static List<RegionData> getRegions() {
        List<Region__c> regions = [
            SELECT Id, Region_Label__c, State_Code__c, Status__c,
                   GeoJSON_Boundary__c, Center_Latitude__c, Center_Longitude__c,
                   Border_Color__c, Fill_Color__c
            FROM Region__c
            WHERE Status__c = 'Active'
            ORDER BY Region_Label__c
        ];
        
        // Get all region IDs
        Set<Id> regionIds = new Set<Id>();
        for (Region__c region : regions) {
            regionIds.add(region.Id);
        }
        
        // OPTIMIZED: Get all job counts in single queries
        Map<Id, Integer> openJobsByRegion = new Map<Id, Integer>();
        Map<Id, Integer> overdueJobsByRegion = new Map<Id, Integer>();
        Map<Id, Integer> totalJobsByRegion = new Map<Id, Integer>();
        Map<Id, Integer> filledJobsByRegion = new Map<Id, Integer>();
        
        // Count jobs by region and status
        for (AggregateResult ar : [
            SELECT Region__c, TR1__Status__c, COUNT(Id) cnt
            FROM TR1__Job__c
            WHERE Region__c IN :regionIds
            GROUP BY Region__c, TR1__Status__c
        ]) {
            Id regionId = (Id)ar.get('Region__c');
            String status = (String)ar.get('TR1__Status__c');
            Integer count = (Integer)ar.get('cnt');
            
            if (!totalJobsByRegion.containsKey(regionId)) {
                totalJobsByRegion.put(regionId, 0);
            }
            totalJobsByRegion.put(regionId, totalJobsByRegion.get(regionId) + count);
            
            if (status == 'Open' || status == 'In Progress') {
                openJobsByRegion.put(regionId, count);
            } else if (status == 'Filled' || status == 'Closed') {
                filledJobsByRegion.put(regionId, count);
            }
        }
        
        // Count overdue jobs
        for (AggregateResult ar : [
            SELECT Region__c, COUNT(Id) cnt
            FROM TR1__Job__c
            WHERE Region__c IN :regionIds
            AND Job_Expiry_Date__c < TODAY
            AND TR1__Status__c NOT IN ('Filled', 'Closed', 'Cancelled')
            GROUP BY Region__c
        ]) {
            Id regionId = (Id)ar.get('Region__c');
            Integer count = (Integer)ar.get('cnt');
            overdueJobsByRegion.put(regionId, count);
        }
        
        // Build result list
        List<RegionData> result = new List<RegionData>();
        
        for(Region__c region : regions) {
            RegionData data = new RegionData();
            data.id = region.Id;
            data.name = region.Region_Label__c;
            data.stateCode = region.State_Code__c;
            data.geoJSON = region.GeoJSON_Boundary__c;
            data.centerLat = region.Center_Latitude__c;
            data.centerLng = region.Center_Longitude__c;
            data.borderColor = region.Border_Color__c != null ? region.Border_Color__c : '#667eea';
            data.fillColor = region.Fill_Color__c != null ? region.Fill_Color__c : '#667eea';
            
            // Get metrics from maps
            data.openJobs = openJobsByRegion.containsKey(region.Id) ? openJobsByRegion.get(region.Id) : 0;
            data.overdueJobs = overdueJobsByRegion.containsKey(region.Id) ? overdueJobsByRegion.get(region.Id) : 0;
            data.totalJobs = totalJobsByRegion.containsKey(region.Id) ? totalJobsByRegion.get(region.Id) : 0;
            data.filledJobs = filledJobsByRegion.containsKey(region.Id) ? filledJobsByRegion.get(region.Id) : 0;
            
            // Calculate fill rate
            if (data.totalJobs > 0) {
                data.fillRate = (Integer)((Decimal)data.filledJobs / data.totalJobs * 100);
            } else {
                data.fillRate = 0;
            }
            
            // Calculate demand spike (simplified - just based on total jobs for now)
            data.demandSpike = data.openJobs > 50 ? 45.0 : (data.openJobs > 30 ? 25.0 : 0.0);
            data.isHotspot = data.demandSpike > 40;
            
            // Simplified avg time to hire
            data.avgTimeToHire = data.totalJobs > 0 ? 32 : 0;
            
            result.add(data);
        }
        
        return result;
    }
    
    /**
     * Get jobs for selected region with priority scoring
     */
    @AuraEnabled(cacheable=true)
    public static List<JobData> getJobsByRegion(Id regionId) {
        List<TR1__Job__c> jobs = [
            SELECT Id, Name, TR1__Status__c, Job_Priority__c, Job_Expiry_Date__c, 
                   CreatedDate, LastModifiedDate,
                   Account__r.Name,
                   Account__r.BillingLatitude,
                   Account__r.BillingLongitude,
                   Owner.Name
            FROM TR1__Job__c
            WHERE Region__c = :regionId
            ORDER BY Job_Priority__c DESC NULLS LAST, Job_Expiry_Date__c ASC NULLS LAST
            LIMIT 100
        ];
        
        Date today = Date.today();
        List<JobData> result = new List<JobData>();
        
        for(TR1__Job__c job : jobs) {
            JobData data = new JobData();
            data.id = job.Id;
            data.name = job.Name;
            data.status = job.TR1__Status__c;
            data.priority = job.Job_Priority__c != null ? job.Job_Priority__c : 'Normal';
            data.dueDate = job.Job_Expiry_Date__c;
            data.accountName = job.Account__r?.Name;
            data.ownerName = job.Owner.Name;
            data.latitude = job.Account__r?.BillingLatitude;
            data.longitude = job.Account__r?.BillingLongitude;
            
            // Calculate days open
            data.daysOpen = job.CreatedDate.date().daysBetween(today);
            
            // Calculate derived fields
            data.isOverdue = job.Job_Expiry_Date__c != null && job.Job_Expiry_Date__c < today;
            
            // Calculate days to fill (for filled jobs)
            if (job.TR1__Status__c == 'Filled' || job.TR1__Status__c == 'Closed') {
                data.daysToFill = job.CreatedDate.date().daysBetween(job.LastModifiedDate.date());
            } else {
                data.daysToFill = null;
            }
            
            // Determine urgency level
            if (data.isOverdue) {
                data.urgencyLevel = 'critical';
            } else if (job.Job_Expiry_Date__c != null && job.Job_Expiry_Date__c <= today.addDays(7)) {
                data.urgencyLevel = 'high';
            } else {
                data.urgencyLevel = 'normal';
            }
            
            // Mock candidate count
            data.candidateCount = (Integer)(Math.random() * 10);
            
            result.add(data);
        }
        
        return result;
    }
    
    /**
     * Get hotspot analysis for dashboard alerts
     * OPTIMIZED: No loops with queries
     */
    @AuraEnabled(cacheable=true)
    public static HotspotAnalysis getHotspotAnalysis() {
        HotspotAnalysis analysis = new HotspotAnalysis();
        analysis.hotspots = new List<HotspotData>();
        analysis.atRisk = new List<HotspotData>();
        analysis.recommendations = new List<String>();
        
        // Get all regions with their job counts
        List<RegionData> regions = getRegions();
        
        for(RegionData region : regions) {
            Decimal spike = region.demandSpike;
            
            // Identify hotspots
            if(spike > 40 || region.openJobs > 50) {
                HotspotData hotspot = new HotspotData();
                hotspot.regionId = region.id;
                hotspot.regionName = region.name;
                hotspot.openJobs = region.openJobs;
                hotspot.overdueJobs = region.overdueJobs;
                hotspot.demandSpike = spike;
                hotspot.avgTimeToHire = region.avgTimeToHire;
                hotspot.severity = 'high';
                hotspot.recommendation = 'High demand: ' + region.openJobs + ' open jobs. Consider adding resources.';
                analysis.hotspots.add(hotspot);
            } 
            // Identify at-risk regions
            else if(region.overdueJobs > 5) {
                HotspotData risk = new HotspotData();
                risk.regionId = region.id;
                risk.regionName = region.name;
                risk.openJobs = region.openJobs;
                risk.overdueJobs = region.overdueJobs;
                risk.demandSpike = spike;
                risk.avgTimeToHire = region.avgTimeToHire;
                risk.severity = region.overdueJobs > 10 ? 'critical' : 'medium';
                risk.recommendation = region.overdueJobs + ' overdue jobs. Immediate intervention required.';
                analysis.atRisk.add(risk);
            }
        }
        
        // Generate recommendations
        if (!analysis.hotspots.isEmpty()) {
            analysis.recommendations.add('⚠️ ' + analysis.hotspots.size() + ' hotspot(s) detected requiring resource allocation');
        }
        if (!analysis.atRisk.isEmpty()) {
            analysis.recommendations.add('🔍 ' + analysis.atRisk.size() + ' region(s) at risk of missing SLAs');
        }
        if (analysis.hotspots.isEmpty() && analysis.atRisk.isEmpty()) {
            analysis.recommendations.add('✅ All regions performing within normal parameters');
        }
        
        return analysis;
    }
    
    /**
     * Get workload balance data for team view
     */
    @AuraEnabled(cacheable=true)
    public static List<RecruiterWorkload> getRecruiterWorkloads() {
        List<User> recruiters = [
            SELECT Id, Name, Title
            FROM User
            WHERE IsActive = true
            AND (Title LIKE '%Recruiter%' OR UserRole.Name LIKE '%Recruit%')
            LIMIT 10
        ];
        
        Set<Id> recruiterIds = new Set<Id>();
        for (User u : recruiters) {
            recruiterIds.add(u.Id);
        }
        
        // Get job counts per recruiter
        Map<Id, Integer> activeJobsMap = new Map<Id, Integer>();
        Map<Id, Integer> overdueJobsMap = new Map<Id, Integer>();
        
        for (AggregateResult ar : [
            SELECT OwnerId, COUNT(Id) cnt
            FROM TR1__Job__c
            WHERE OwnerId IN :recruiterIds
            AND TR1__Status__c NOT IN ('Filled', 'Closed', 'Cancelled')
            GROUP BY OwnerId
        ]) {
            activeJobsMap.put((Id)ar.get('OwnerId'), (Integer)ar.get('cnt'));
        }
        
        for (AggregateResult ar : [
            SELECT OwnerId, COUNT(Id) cnt
            FROM TR1__Job__c
            WHERE OwnerId IN :recruiterIds
            AND Job_Expiry_Date__c < TODAY
            AND TR1__Status__c NOT IN ('Filled', 'Closed', 'Cancelled')
            GROUP BY OwnerId
        ]) {
            overdueJobsMap.put((Id)ar.get('OwnerId'), (Integer)ar.get('cnt'));
        }
        
        List<RecruiterWorkload> workloads = new List<RecruiterWorkload>();
        
        for(User recruiter : recruiters) {
            RecruiterWorkload workload = new RecruiterWorkload();
            workload.recruiterId = recruiter.Id;
            workload.recruiterName = recruiter.Name;
            
            Integer activeJobs = activeJobsMap.containsKey(recruiter.Id) ? activeJobsMap.get(recruiter.Id) : 0;
            Integer overdueJobs = overdueJobsMap.containsKey(recruiter.Id) ? overdueJobsMap.get(recruiter.Id) : 0;
            
            workload.activeJobs = activeJobs;
            workload.overdueJobs = overdueJobs;
            workload.capacityPercentage = calculateCapacity(activeJobs);
            workload.workloadStatus = determineWorkloadStatus(activeJobs);
            workload.avgTimeToFill = 32; // Simplified
            
            workloads.add(workload);
        }
        
        return workloads;
    }
    
    /**
     * Get performance metrics by territory
     */
    @AuraEnabled(cacheable=true)
    public static List<TerritoryPerformance> getTerritoryPerformance() {
        List<RegionData> regions = getRegions();
        List<TerritoryPerformance> performances = new List<TerritoryPerformance>();
        
        for(RegionData region : regions) {
            TerritoryPerformance perf = new TerritoryPerformance();
            perf.regionId = region.id;
            perf.regionName = region.name;
            perf.fillRate = region.fillRate;
            perf.avgDaysToFill = region.avgTimeToHire;
            perf.placementsThisMonth = region.filledJobs;
            perf.revenue = region.filledJobs * 3500;
            perf.trend = region.demandSpike > 20 ? 'up' : 'stable';
            
            performances.add(perf);
        }
        
        return performances;
    }
    
    // ============ HELPER METHODS ============
    
    private static Integer calculateCapacity(Integer activeJobs) {
        Integer targetCapacity = 15;
        return (Integer)((Decimal)activeJobs / targetCapacity * 100);
    }
    
    private static String determineWorkloadStatus(Integer activeJobs) {
        if (activeJobs > 20) return 'overloaded';
        if (activeJobs > 15) return 'stressed';
        if (activeJobs < 10) return 'capacity';
        return 'optimal';
    }
    
    // ============ WRAPPER CLASSES ============
    
    public class RegionData {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String stateCode;
        @AuraEnabled public String geoJSON;
        @AuraEnabled public Decimal centerLat;
        @AuraEnabled public Decimal centerLng;
        @AuraEnabled public String borderColor;
        @AuraEnabled public String fillColor;
        @AuraEnabled public Integer openJobs;
        @AuraEnabled public Integer overdueJobs;
        @AuraEnabled public Integer totalJobs;
        @AuraEnabled public Integer filledJobs;
        @AuraEnabled public Integer fillRate;
        @AuraEnabled public Decimal demandSpike;
        @AuraEnabled public Boolean isHotspot;
        @AuraEnabled public Integer avgTimeToHire;
    }
    
    public class JobData {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String priority;
        @AuraEnabled public Datetime dueDate;
        @AuraEnabled public Boolean isOverdue;
        @AuraEnabled public Integer daysOpen;
        @AuraEnabled public Integer daysToFill;
        @AuraEnabled public String urgencyLevel;
        @AuraEnabled public Integer candidateCount;
        @AuraEnabled public String accountName;
        @AuraEnabled public String ownerName;
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
    }
    
    public class HotspotAnalysis {
        @AuraEnabled public List<HotspotData> hotspots;
        @AuraEnabled public List<HotspotData> atRisk;
        @AuraEnabled public List<String> recommendations;
    }
    
    public class HotspotData {
        @AuraEnabled public Id regionId;
        @AuraEnabled public String regionName;
        @AuraEnabled public Integer openJobs;
        @AuraEnabled public Integer overdueJobs;
        @AuraEnabled public Decimal demandSpike;
        @AuraEnabled public Integer avgTimeToHire;
        @AuraEnabled public String severity;
        @AuraEnabled public String recommendation;
    }
    
    public class RecruiterWorkload {
        @AuraEnabled public Id recruiterId;
        @AuraEnabled public String recruiterName;
        @AuraEnabled public Integer activeJobs;
        @AuraEnabled public Integer overdueJobs;
        @AuraEnabled public Integer capacityPercentage;
        @AuraEnabled public String workloadStatus;
        @AuraEnabled public Integer avgTimeToFill;
    }
    
    public class TerritoryPerformance {
        @AuraEnabled public Id regionId;
        @AuraEnabled public String regionName;
        @AuraEnabled public Integer fillRate;
        @AuraEnabled public Integer avgDaysToFill;
        @AuraEnabled public Integer placementsThisMonth;
        @AuraEnabled public Decimal revenue;
        @AuraEnabled public String trend;
    }
}