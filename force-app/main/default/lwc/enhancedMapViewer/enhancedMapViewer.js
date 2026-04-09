import { LightningElement, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LEAFLET from '@salesforce/resourceUrl/leaflet';

// Import Apex methods
import getRegions from '@salesforce/apex/SimplePOCController.getRegions';
import getJobsByRegion from '@salesforce/apex/SimplePOCController.getJobsByRegion';
import getHotspotAnalysis from '@salesforce/apex/SimplePOCController.getHotspotAnalysis';
import getRecruiterWorkloads from '@salesforce/apex/SimplePOCController.getRecruiterWorkloads';
import getTerritoryPerformance from '@salesforce/apex/SimplePOCController.getTerritoryPerformance';

export default class RegionalIntelligenceMap extends LightningElement {
    // Core data
    @track selectedRegion = null;
    @track regions = [];
    @track jobs = [];
    @track currentView = 'daily';
    
    // KPIs
    @track kpis = {
        total: 0,
        overdue: 0,
        inProgress: 0,
        filled: 0
    };
    
    // Dashboard data
    @track territorySummaries = [];
    @track recruiterWorkloads = [];
    @track territoryPerformance = [];
    @track hotspotData = null;
    
    // Map state
    mapInitialized = false;
    leafletMap;
    regionLayers = new Map();
    jobMarkers = [];
    
    // Computed properties for views
    get showDailyView() { return this.currentView === 'daily'; }
    get showWorkloadView() { return this.currentView === 'workload'; }
    get showPerformanceView() { return this.currentView === 'performance'; }
    
    get isDailyView() { return this.currentView === 'daily' ? 'brand' : 'neutral'; }
    get isWorkloadView() { return this.currentView === 'workload' ? 'brand' : 'neutral'; }
    get isPerformanceView() { return this.currentView === 'performance' ? 'brand' : 'neutral'; }
    
    get sidePanelClass() {
        return this.selectedRegion ? 'side-panel' : 'side-panel side-panel-hidden';
    }
    
    // Summary counts
    get pastSLACount() {
        return this.regions.reduce((sum, r) => sum + (r.overdueJobs || 0), 0);
    }
    
    get dueTodayCount() {
        return Math.floor(this.regions.reduce((sum, r) => sum + (r.openJobs || 0), 0) * 0.15);
    }
    
    get noCandidatesCount() {
        return Math.floor(this.pastSLACount * 0.4);
    }
    
    get territoryHealthScore() {
        if (!this.selectedRegion) return 0;
        const fillRate = this.selectedRegion.fillRate || 0;
        const onTimeRate = this.selectedRegion.openJobs > 0 
            ? 100 - ((this.selectedRegion.overdueJobs / this.selectedRegion.openJobs) * 100)
            : 100;
        return Math.round((fillRate + onTimeRate) / 2);
    }
    
    get workloadStatus() {
        if (!this.selectedRegion) return 'Unknown';
        const jobsPerRecruiter = this.selectedRegion.openJobs / 3;
        if (jobsPerRecruiter > 20) return 'Overloaded';
        if (jobsPerRecruiter > 15) return 'Stressed';
        return 'Optimal';
    }
    
    get hasNoOverdueJobs() {
        return !this.selectedRegion || this.selectedRegion.overdueJobs === 0;
    }
    
    // Lifecycle hooks
    connectedCallback() {
        console.log('🚀 Regional Intelligence Map - Component Connected');
    }
    
    renderedCallback() {
        if (this.mapInitialized) {
            return;
        }
        this.mapInitialized = true;
        console.log('📍 Starting map initialization...');
        this.loadLeaflet();
    }
    
    // Load Leaflet library
    loadLeaflet() {
        console.log('📦 Loading Leaflet library...');
        console.log('📦 Static Resource URL:', LEAFLET);
        
        Promise.all([
            loadStyle(this, LEAFLET + '/dist/leaflet.css'),
            loadScript(this, LEAFLET + '/dist/leaflet.js')
        ])
        .then(() => {
            console.log('✅ Leaflet loaded successfully');
            
            // Check if Leaflet is available
            if (typeof L !== 'undefined') {
                console.log('✅ Leaflet version:', L.version);
                this.initializeMap();
            } else {
                throw new Error('Leaflet (L) is undefined after loading');
            }
        })
        .catch(error => {
            console.error('❌ Error loading Leaflet:', error);
            this.showError('Map Load Error', 'Failed to load map library: ' + error.message);
        });
    }
    
    // Initialize Leaflet map
    initializeMap() {
        console.log('🗺️ Initializing map...');
        
        // Wait for DOM to be ready
        setTimeout(() => {
            const mapElement = this.template.querySelector('.map-container');
            
            if (!mapElement) {
                console.error('❌ Map container not found');
                this.showError('Map Error', 'Map container element not found in DOM');
                return;
            }
            
            console.log('✅ Map container found');
            
            try {
                // Create Leaflet map
                this.leafletMap = L.map(mapElement, {
                    zoomControl: true,
                    scrollWheelZoom: true,
                    dragging: true,
                    doubleClickZoom: true
                }).setView([39.8283, -98.5795], 4);
                
                console.log('✅ Leaflet map instance created');
                
                // Add OpenStreetMap tiles
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                    maxZoom: 19,
                    minZoom: 3
                }).addTo(this.leafletMap);
                
                console.log('✅ Tile layer added');
                
                // Force map to render properly
                setTimeout(() => {
                    this.leafletMap.invalidateSize();
                    console.log('✅ Map size invalidated');
                }, 200);
                
                // Load data
                this.loadAllData();
                
            } catch (error) {
                console.error('❌ Error creating map:', error);
                this.showError('Map Error', 'Failed to initialize map: ' + error.message);
            }
        }, 100);
    }
    
    // Load all data
    loadAllData() {
        console.log('📊 Loading all data...');
        
        // Load regions
        getRegions()
            .then(data => {
                console.log('✅ Regions loaded:', data.length);
                this.regions = data;
                this.processRegionIntelligence(data);
                this.renderRegions(data);
            })
            .catch(error => {
                console.error('❌ Error loading regions:', error);
                this.showError('Data Error', 'Failed to load regions: ' + (error.body?.message || error.message));
            });
        
        // Load hotspot analysis
        getHotspotAnalysis()
            .then(data => {
                console.log('✅ Hotspot analysis loaded');
                this.hotspotData = data;
            })
            .catch(error => {
                console.error('❌ Error loading hotspots:', error);
            });
        
        // Load workload data
        getRecruiterWorkloads()
            .then(data => {
                console.log('✅ Recruiter workloads loaded:', data.length);
                this.recruiterWorkloads = data;
            })
            .catch(error => {
                console.error('❌ Error loading workloads:', error);
            });
        
        // Load performance data
        getTerritoryPerformance()
            .then(data => {
                console.log('✅ Territory performance loaded:', data.length);
                this.territoryPerformance = data;
            })
            .catch(error => {
                console.error('❌ Error loading performance:', error);
            });
    }
    
    // Process region intelligence
    processRegionIntelligence(regions) {
        console.log('🧠 Processing region intelligence...');
        
        this.territorySummaries = regions.map(region => ({
            id: region.id,
            name: region.name,
            openJobs: region.openJobs || 0,
            urgentJobs: region.overdueJobs || 0,
            fillRate: region.fillRate || 0,
            colorStyle: `background-color: ${this.getRegionColor(region)}`,
            demandSpike: region.demandSpike || 0,
            isHotspot: region.isHotspot || false
        }));
    }
    
    // Render regions on map
    renderRegions(regions) {
        if (!this.leafletMap) {
            console.warn('⚠️ Map not ready yet');
            return;
        }
        
        console.log('🎨 Rendering', regions.length, 'regions on map');
        
        // Clear existing layers
        this.regionLayers.forEach(layer => {
            this.leafletMap.removeLayer(layer);
        });
        this.regionLayers.clear();
        
        regions.forEach(region => {
            if (!region.centerLat || !region.centerLng) {
                console.warn('⚠️ Region missing coordinates:', region.name);
                return;
            }
            
            const color = this.getRegionColor(region);
            const radius = Math.max(10, Math.sqrt(region.openJobs || 1) * 4);
            
            // Create circle marker
            const circle = L.circleMarker([region.centerLat, region.centerLng], {
                radius: radius,
                fillColor: color,
                color: '#fff',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.7
            }).addTo(this.leafletMap);
            
            // Add hotspot indicator
            if (region.isHotspot) {
                L.marker([region.centerLat, region.centerLng], {
                    icon: L.divIcon({
                        className: 'hotspot-icon',
                        html: '<div style="font-size: 24px; margin-top: -30px;">🔥</div>',
                        iconSize: [30, 30]
                    })
                }).addTo(this.leafletMap);
            }
            
            // Create popup
            const popupContent = `
                <div style="min-width: 200px; font-family: Arial, sans-serif;">
                    <strong style="font-size: 14px;">${region.name}</strong><br/>
                    ${region.isHotspot ? '<span style="color: #d32f2f; font-weight: bold;">🔥 HOTSPOT</span><br/>' : ''}
                    <div style="margin-top: 8px;">
                        <strong>Open Jobs:</strong> ${region.openJobs || 0}<br/>
                        <strong>Overdue:</strong> <span style="color: #d32f2f;">${region.overdueJobs || 0}</span><br/>
                        <strong>Fill Rate:</strong> ${region.fillRate || 0}%<br/>
                        <strong>Demand Spike:</strong> ${Math.round(region.demandSpike || 0)}%
                    </div>
                </div>
            `;
            
            circle.bindPopup(popupContent);
            
            // Click handler
            circle.on('click', () => {
                this.handleRegionSelect(region);
            });
            
            this.regionLayers.set(region.id, circle);
            
            console.log('✅ Rendered region:', region.name);
        });
        
        console.log('✅ All regions rendered');
    }
    
    // Get region color based on status
    getRegionColor(region) {
        if (region.overdueJobs > 10) return '#d32f2f'; // Critical red
        if (region.overdueJobs > 5) return '#f57c00'; // Warning orange
        if (region.isHotspot) return '#7b1fa2'; // Hotspot purple
        if (region.demandSpike > 20) return '#1976d2'; // High demand blue
        return '#43a047'; // Normal green
    }
    
    // Handle region selection
    handleRegionSelect(region) {
        console.log('📍 Region selected:', region.name);
        this.selectedRegion = region;
        
        // Highlight selected region
        this.regionLayers.forEach((layer, id) => {
            if (id === region.id) {
                layer.setStyle({ weight: 4, fillOpacity: 0.9 });
            } else {
                layer.setStyle({ weight: 2, fillOpacity: 0.7 });
            }
        });
        
        // Pan to region
        this.leafletMap.setView([region.centerLat, region.centerLng], 7);
        
        // Update KPIs
        this.updateRegionKPIs(region);
        
        // Load jobs for region
        this.loadJobsForRegion(region.id);
    }
    
    // Load jobs for selected region
    loadJobsForRegion(regionId) {
        console.log('💼 Loading jobs for region:', regionId);
        
        getJobsByRegion({ regionId: regionId })
            .then(data => {
                console.log('✅ Jobs loaded:', data.length);
                this.jobs = data;
                this.renderJobMarkers(data);
            })
            .catch(error => {
                console.error('❌ Error loading jobs:', error);
                this.showError('Data Error', 'Failed to load jobs: ' + (error.body?.message || error.message));
            });
    }
    
    // Render job markers on map
    renderJobMarkers(jobs) {
        console.log('📌 Rendering', jobs.length, 'job markers');
        
        // Clear existing markers
        this.jobMarkers.forEach(marker => {
            this.leafletMap.removeLayer(marker);
        });
        this.jobMarkers = [];
        
        jobs.forEach(job => {
            if (!job.latitude || !job.longitude) {
                console.warn('⚠️ Job missing coordinates:', job.name);
                return;
            }
            
            const icon = this.getJobIcon(job);
            
            const marker = L.marker([job.latitude, job.longitude], {
                icon: icon
            }).addTo(this.leafletMap);
            
            const popupContent = `
                <div style="min-width: 180px; font-family: Arial, sans-serif;">
                    <strong style="font-size: 13px;">${job.name}</strong><br/>
                    <div style="margin-top: 6px; font-size: 12px;">
                        <strong>Status:</strong> ${job.status}<br/>
                        <strong>Priority:</strong> ${job.priority}<br/>
                        ${job.accountName ? `<strong>Account:</strong> ${job.accountName}<br/>` : ''}
                        <strong>Owner:</strong> ${job.ownerName}<br/>
                        ${job.isOverdue ? '<span style="color: #d32f2f; font-weight: bold;">⚠️ OVERDUE</span>' : ''}
                    </div>
                </div>
            `;
            
            marker.bindPopup(popupContent);
            this.jobMarkers.push(marker);
        });
        
        console.log('✅ Job markers rendered');
    }
    
    // Get job marker icon based on status
    getJobIcon(job) {
        let color = '#43a047'; // Green - on track
        if (job.isOverdue) {
            color = '#d32f2f'; // Red - overdue
        } else if (job.urgencyLevel === 'high') {
            color = '#ff9800'; // Orange - high priority
        }
        
        return L.divIcon({
            className: 'job-marker',
            html: `<div style="
                background-color: ${color};
                width: 14px;
                height: 14px;
                border-radius: 50%;
                border: 2px solid white;
                box-shadow: 0 2px 5px rgba(0,0,0,0.3);
            "></div>`,
            iconSize: [14, 14],
            iconAnchor: [7, 7]
        });
    }
    
    // Update KPIs for selected region
    updateRegionKPIs(region) {
        this.kpis = {
            total: region.openJobs || 0,
            overdue: region.overdueJobs || 0,
            inProgress: Math.floor((region.openJobs || 0) * 0.6),
            filled: region.filledJobs || 0
        };
    }
    
    // View switching handlers
    handleDailyView() {
        this.currentView = 'daily';
    }
    
    handleWorkloadView() {
        this.currentView = 'workload';
    }
    
    handlePerformanceView() {
        this.currentView = 'performance';
    }
    
    // Filter handlers
    handleShowPastSLA() {
        console.log('🔍 Filtering: Past SLA');
        this.filterRegionsByStatus('overdue');
    }
    
    handleShowDueToday() {
        console.log('🔍 Filtering: Due Today');
        this.filterRegionsByStatus('due-today');
    }
    
    handleShowNoCandidates() {
        console.log('🔍 Filtering: No Candidates');
        this.filterRegionsByStatus('no-candidates');
    }
    
    filterRegionsByStatus(status) {
        this.regionLayers.forEach((layer, regionId) => {
            const region = this.regions.find(r => r.id === regionId);
            if (!region) return;
            
            let highlight = false;
            if (status === 'overdue' && region.overdueJobs > 0) {
                highlight = true;
            } else if (status === 'hotspot' && region.isHotspot) {
                highlight = true;
            }
            
            layer.setStyle({
                fillOpacity: highlight ? 0.9 : 0.3,
                weight: highlight ? 3 : 2
            });
        });
    }
    
    // Territory card click handler
    handleTerritoryCardClick(event) {
        const regionId = event.currentTarget.dataset.id;
        const region = this.regions.find(r => r.id === regionId);
        if (region) {
            this.handleRegionSelect(region);
        }
    }
    
    // Close side panel
    handleCloseSidePanel() {
        this.selectedRegion = null;
        this.jobs = [];
        
        // Reset region styling
        this.regionLayers.forEach(layer => {
            layer.setStyle({ weight: 2, fillOpacity: 0.7 });
        });
        
        // Clear job markers
        this.jobMarkers.forEach(marker => {
            this.leafletMap.removeLayer(marker);
        });
        this.jobMarkers = [];
    }
    
    // Action handlers (placeholders)
    handleShowRecruiterTerritory(event) {
        const recruiterId = event.currentTarget.dataset.id;
        this.showToast('Info', `Showing territories for recruiter ${recruiterId}`, 'info');
    }
    
    handleAutoBalance() {
        this.showToast('Success', 'Workload auto-balance initiated', 'success');
    }
    
    handlePerformanceCardClick(event) {
        const regionId = event.currentTarget.dataset.id;
        const region = this.regions.find(r => r.id === regionId);
        if (region) {
            this.handleRegionSelect(region);
        }
    }
    
    handleCompareMode() {
        this.showToast('Info', 'Territory comparison mode activated', 'info');
    }
    
    // Toast notification
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
    
    showError(title, message) {
        this.showToast(title, message, 'error');
    }
}