import { LightningElement, api, track } from 'lwc';

export default class ReleaseDetailModal extends LightningElement {

    @api projectId;

    _release   = null;   
    @track formData  = {};
    @track isEditMode = false;
    @track isSaving   = false;

    @api
    set release(val) {
        this._release  = val || null;
        this.isEditMode = false;
        this.formData   = val ? { ...val } : {};
    }
    get release() { return this._release || {}; }

    
    get isNewMode()  { return !this._release?.Id; }
    get isFormMode() { return this.isNewMode || this.isEditMode; }
    get modalTitle() {
        if (this.isNewMode)   return 'New Release';
        if (this.isEditMode)  return 'Edit: ' + (this._release?.Name || 'Release');
        return this._release?.Name || 'Release Details';
    }
    get saveLabel() { return this.isSaving ? 'Saving…' : (this.isNewMode ? 'Create Release' : 'Save Changes'); }

    
    handleClose()      { this.dispatchEvent(new CustomEvent('close')); }
    stop(e)            { e.stopPropagation(); }
    handleBdClick()    { this.handleClose(); }

    handleStartEdit() {
        this.formData   = { ...this._release };
        this.isEditMode = true;
    }

    handleCancelEdit() {
        this.formData   = this._release ? { ...this._release } : {};
        this.isEditMode = false;
        if (this.isNewMode) this.handleClose();
    }

    handleInput(event) {
        const field = event.target.dataset.field;
        this.formData = { ...this.formData, [field]: event.target.value };
    }

    handleSave() {
        if (!this.formData.Name || !this.formData.Name.trim()) {
            this.dispatchEvent(new CustomEvent('validationerror',
                { detail: 'Release Name is required', bubbles:true, composed:true }));
            return;
        }
        this.isSaving = true;
        
        const fd = this.formData;
        const payload = {
            id:             fd.Id             || null,
            name:           fd.Name,
            version:        fd.Version__c     || null,
            status:         fd.Status__c      || null,
            stage:          fd.Stage__c       || null,
            releaseNotes:   fd.Release_Notes__c   || null,
            releaseManager: fd.Release_Manager__c || null,
            goLiveDate:     fd.Go_Live_Date__c    || null,
            codeFreeze:     fd.Code_Freeze_Date__c || null,
            releaseDate:    fd.Release_Date__c    || null,
            projectId:      this.projectId,
        };
        this.dispatchEvent(new CustomEvent('save', {
            bubbles:  true,
            composed: true,
            detail:   payload,
        }));
        
        setTimeout(() => { this.isSaving = false; }, 5000);
    }

    handleNav() {
        if (!this._release?.Id) return;
        this.dispatchEvent(new CustomEvent('navigate', { bubbles:true, composed:true,
            detail:{ recordId: this._release.Id, objectApiName:'Release__c' } }));
    }
}