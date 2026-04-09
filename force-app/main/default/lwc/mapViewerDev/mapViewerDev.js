import { LightningElement, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LEAFLET from '@salesforce/resourceUrl/leaflet';

// Import Apex methods
import getRegions from '@salesforce/apex/SimplePOCController.getRegions';
import getJobsByRegion from '@salesforce/apex/SimplePOCController.getJobsByRegion';

export default class MapViewerDev extends LightningElement {
    @track selectedRegion = null;
    @track regions = [];
    @track jobs = [];
    @track territorySummaries = [];
    
    mapInitialized = false;
    leafletMap;
    regionLayers = new Map();
    
    @track kpis = {
        total: 0,
        overdue: 0,
        inProgress: 0,
        filled: 0
    };
    
    get sidePanelClass() {
        return this.selectedRegion ? 'side-panel' : 'side-panel side-panel-hidden';
    }
    
    get pastSLACount() {
        return this.regions.reduce((sum, r) => sum + (r.overdueJobs || 0), 0);
    }
    
    connectedCallback() {
        console.log('🚀 Component Connected');
        console.log('📦 Static Resource Path:', LEAFLET);
    }

    renderedCallback() {
        if (this.mapInitialized) {
            return;
        }
        this.mapInitialized = true;
        console.log('📍 Starting initialization...');
        
        setTimeout(() => {
            this.loadLeaflet();
        }, 100);
    }

    loadLeaflet() {
        console.log('📦 Loading Leaflet library...');
        
        // FIXED: Using /dist/ path
        const cssPath = LEAFLET + '/dist/leaflet.css';
        const jsPath = LEAFLET + '/dist/leaflet.js';
        
        console.log('CSS Path:', cssPath);
        console.log('JS Path:', jsPath);

        Promise.all([
            loadStyle(this, cssPath),
            loadScript(this, jsPath)
        ])
        .then(() => {
            console.log('✅ Leaflet files loaded');
            
            if (typeof L === 'undefined') {
                throw new Error('Leaflet (L) is undefined after loading');
            }
            
            console.log('✅ Leaflet version:', L.version);
            
            setTimeout(() => {
                this.initializeMap();
            }, 200);
        })
        .catch(error => {
            console.error('❌ Error loading Leaflet:', error);
            this.showError('Map Error', 'Failed to load map library: ' + error.message);
        });
    }

    initializeMap() {
        console.log('🗺️ Initializing map...');
        
        const mapElement = this.template.querySelector('.map-container');
        
        if (!mapElement) {
            console.error('❌ Map container not found');
            return;
        }
        
        console.log('✅ Map container found');
        console.log('Container size:', {
            width: mapElement.offsetWidth,
            height: mapElement.offsetHeight
        });

        try {
            this.leafletMap = L.map(mapElement, {
                zoomControl: true,
                scrollWheelZoom: true
            }).setView([39.8283, -98.5795], 4);
            
            console.log('✅ Map instance created');

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap contributors',
                maxZoom: 19
            }).addTo(this.leafletMap);
            
            console.log('✅ Tile layer added');

            setTimeout(() => {
                this.leafletMap.invalidateSize();
                console.log('✅ Map resized');
            }, 100);

            this.loadRegions();

            console.log('🎉 MAP SUCCESSFULLY INITIALIZED!');

        } catch (error) {
            console.error('❌ Error creating map:', error);
            this.showError('Map Error', 'Failed to initialize map: ' + error.message);
        }
    }

    loadRegions() {
        console.log('📊 Loading regions...');
        
        getRegions()
            .then(data => {
                console.log('✅ Regions loaded:', data.length);
                this.regions = data;
                this.processRegions(data);
                this.renderRegions(data);
            })
            .catch(error => {
                console.error('❌ Error loading regions:', error);
                this.showError('Data Error', 'Failed to load regions: ' + (error.body?.message || error.message));
            });
    }

    processRegions(regions) {
        this.territorySummaries = regions.map(region => ({
            id: region.id,
            name: region.name,
            openJobs: region.openJobs || 0,
            urgentJobs: region.overdueJobs || 0,
            fillRate: region.fillRate || 0,
            colorStyle: `background-color: ${this.getRegionColor(region)}`,
            isHotspot: region.isHotspot || false
        }));
    }

    renderRegions(regions) {
        if (!this.leafletMap) {
            console.warn('⚠️ Map not ready');
            return;
        }

        console.log('🎨 Rendering', regions.length, 'regions');

        regions.forEach(region => {
            if (!region.centerLat || !region.centerLng) {
                console.warn('⚠️ Region missing coordinates:', region.name);
                return;
            }

            const color = this.getRegionColor(region);
            const radius = Math.max(10, Math.sqrt(region.openJobs || 1) * 4);

            const circle = L.circleMarker([region.centerLat, region.centerLng], {
                radius: radius,
                fillColor: color,
                color: '#fff',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.7
            }).addTo(this.leafletMap);

            const popupContent = `
                <div style="min-width: 200px;">
                    <strong>${region.name}</strong><br/>
                    ${region.isHotspot ? '🔥 <strong>HOTSPOT</strong><br/>' : ''}
                    Open Jobs: ${region.openJobs || 0}<br/>
                    Overdue: ${region.overdueJobs || 0}<br/>
                    Fill Rate: ${region.fillRate || 0}%
                </div>
            `;

            circle.bindPopup(popupContent);
            circle.on('click', () => this.handleRegionSelect(region));

            this.regionLayers.set(region.id, circle);
        });

        console.log('✅ All regions rendered');
    }

    getRegionColor(region) {
        if (region.overdueJobs > 10) return '#d32f2f';
        if (region.overdueJobs > 5) return '#f57c00';
        if (region.isHotspot) return '#7b1fa2';
        return '#43a047';
    }

    handleRegionSelect(region) {
        console.log('📍 Region selected:', region.name);
        this.selectedRegion = region;

        this.regionLayers.forEach((layer, id) => {
            if (id === region.id) {
                layer.setStyle({ weight: 4, fillOpacity: 0.9 });
            } else {
                layer.setStyle({ weight: 2, fillOpacity: 0.7 });
            }
        });

        this.leafletMap.setView([region.centerLat, region.centerLng], 7);
        this.updateRegionKPIs(region);
        this.loadJobsForRegion(region.id);
    }

    updateRegionKPIs(region) {
        this.kpis = {
            total: region.openJobs || 0,
            overdue: region.overdueJobs || 0,
            inProgress: Math.floor((region.openJobs || 0) * 0.6),
            filled: region.filledJobs || 0
        };
    }

    loadJobsForRegion(regionId) {
        console.log('💼 Loading jobs for region:', regionId);
        
        getJobsByRegion({ regionId: regionId })
            .then(data => {
                console.log('✅ Jobs loaded:', data.length);
                this.jobs = data;
            })
            .catch(error => {
                console.error('❌ Error loading jobs:', error);
            });
    }

    handleCloseSidePanel() {
        this.selectedRegion = null;
        this.jobs = [];
        
        this.regionLayers.forEach(layer => {
            layer.setStyle({ weight: 2, fillOpacity: 0.7 });
        });
    }

    handleTerritoryCardClick(event) {
        const regionId = event.currentTarget.dataset.id;
        const region = this.regions.find(r => r.id === regionId);
        if (region) {
            this.handleRegionSelect(region);
        }
    }

    showError(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
            mode: 'sticky'
        }));
    }

    get territoryHealthScore() {
        if (!this.selectedRegion) return 0;
        return Math.round((this.selectedRegion.fillRate || 0));
    }

    get workloadStatus() {
        if (!this.selectedRegion) return 'Unknown';
        const jobs = this.selectedRegion.openJobs || 0;
        if (jobs > 60) return 'Overloaded';
        if (jobs > 40) return 'Stressed';
        return 'Optimal';
    }

    get hasNoOverdueJobs() {
        return !this.selectedRegion || this.selectedRegion.overdueJobs === 0;
    }
}