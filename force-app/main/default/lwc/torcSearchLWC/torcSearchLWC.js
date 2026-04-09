import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getSearchURL from '@salesforce/apex/JobMatchController.getSearchURL';
import getOrgId from '@salesforce/apex/JobMatchController.getOrgId';

export default class TorcSearchLWC extends LightningElement {
    @track iframeSrc;
    @track isFullscreen = true;

    torcjobid;
    torcjobsfdcid;
    fedrated;
    torcUserEmail;
    baseSearchURL;
    orgId;

    // ---------- UI getters ----------

    
    get sfdcHomeUrl() {
        return '/lightning/page/home';
    }
    get jobDetailUrl() {
        return this.torcjobsfdcid ? `/lightning/r/TR1__Job__c/${this.torcjobsfdcid}/view` : '';
    }
    get fullscreenLabel() {
        return this.isFullscreen ? 'Exit Fullscreen' : 'Toggle Fullscreen';
    }
    get fsRootClass() {
        // Adds 'pseudo-fullscreen' when toggled on
        return `fs-root${this.isFullscreen ? ' pseudo-fullscreen' : ''}`;
    }

    // ---------- Wires ----------
    @wire(getSearchURL)
    wiredSearchURL({ data, error }) {
        if (data) {
            this.baseSearchURL = data;
            this.buildIframeSrc();
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error('Error loading search URL:', error);
        }
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (!pageRef) return;
        this.torcjobid     = pageRef?.state?.c__torcjobid;
        this.fedrated      = pageRef?.state?.c__fedrated;
        this.torcjobsfdcid = pageRef?.state?.c__torcjobsfdcid;
        this.torcUserEmail = pageRef?.state?.c__torcuseremail;
        this.buildIframeSrc();
    }

    @wire(getOrgId)
    wiredOrgId({ error, data }) {
        if (data) {
            this.orgId = data;
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error('Error fetching Org ID:', error);
        }
    }

    // ---------- URL builder ----------
    buildIframeSrc() {
        if (!this.baseSearchURL) return;

        let url = `${this.baseSearchURL}`;

        if (this.torcjobid) {
            url = `${this.baseSearchURL}#/jobOpps/${this.torcjobid}/details?autoGoogleSignIn=true`;
            if (this.fedrated) {
                url = `${this.baseSearchURL}#/jobOpps/${this.torcjobid}/details?autoGoogleSignIn=true&tab=pre-candidates`;
            }
        } else if (this.torcjobsfdcid) {
            url = `${this.baseSearchURL}#/jobOpps?sfdcexternalid=${this.torcjobsfdcid}&autoGoogleSignIn=true`;
        } else if (this.torcUserEmail) {
            url = `${this.baseSearchURL}#/usermanager?autoGoogleSignIn=true&search='${encodeURIComponent(this.torcUserEmail)}`;
        }

        this.iframeSrc = url;
    }

    // ---------- External action ----------
    handleTextKernelExternalClick() {
        if (this.orgId && this.torcjobsfdcid) {
            const matchQuery = `jobId=${this.orgId}_${this.torcjobsfdcid}&selectedTab=reach`;
            const encodedQuery = encodeURIComponent(matchQuery);
            const url = `/lightning/n/Textkernel1__TextkernelPortal?Textkernel1__match_query=${encodedQuery}`;
            window.open(url, '_blank');
        }
    }

    // ---------- Pseudo fullscreen (CSS-based, LWS-safe) ----------
    connectedCallback() {
        // Allow ESC to exit pseudo fullscreen
        this._onKeydown = (e) => {
            if (this.isFullscreen && e.key === 'Escape') {
                this.isFullscreen = false;
                try { document.body.style.overflow = ''; } catch (err) {}
                const root = this.template?.querySelector('[data-id="fs-root"]');
                root && root.focus();
            }
        };
        window.addEventListener('keydown', this._onKeydown);
    }

    disconnectedCallback() {
        window.removeEventListener('keydown', this._onKeydown);
    }

    handleToggleFullscreen() {
        this.isFullscreen = !this.isFullscreen;

        // Prevent background scroll while "fullscreen"
        try {
            document.body.style.overflow = this.isFullscreen ? 'hidden' : '';
        } catch (e) {
            // ignore if blocked by LWS
        }

        // Focus container so ESC works immediately
        const root = this.template.querySelector('[data-id="fs-root"]');
        root && root.focus();
    }
}