/**
 * jobAdGenerator.js - Address via Apex
 */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

// Apex Controllers
import generateJobAd from '@salesforce/apex/JobAdGeneratorController.generateJobAdFromJob';
import getFieldsConfig from '@salesforce/apex/JobAdGeneratorController.getIncludeFieldsConfig';
import getJobAddress from '@salesforce/apex/JobAdGeneratorController.getJobAddress';

// Schema Imports
import JOB_NAME from '@salesforce/schema/TR1__Job__c.Name';
import JOB_DESC from '@salesforce/schema/TR1__Job__c.TR1__Client_Job_Description__c';
import JOB_RESP from '@salesforce/schema/TR1__Job__c.TR1__Responsibilities__c';
import JOB_TYPE from '@salesforce/schema/TR1__Job__c.Job_Type__c';
import JOB_COUNTRY from '@salesforce/schema/TR1__Job__c.Billing_Country__c';
import JOB_ACCOUNT from '@salesforce/schema/TR1__Job__c.TR1__Account_Name__c';
import JOB_INDUSTRY from '@salesforce/schema/TR1__Job__c.TR1__Industry__c';
import JOB_EDU from '@salesforce/schema/TR1__Job__c.Education_Requirements__c';
import JOB_GENERATED_AD from '@salesforce/schema/TR1__Job__c.Generated_Job_Ad__c';

const JOB_FIELDS = [
    JOB_NAME, JOB_DESC, JOB_RESP, JOB_TYPE, JOB_COUNTRY, 
    JOB_ACCOUNT, JOB_INDUSTRY, JOB_EDU
];

const SKILLS_FIELDS = [
    'TR1__Skills__c.TR1__Skill_Code__c',
    'TR1__Skills__c.TR1__Master_Skill__r.TR1__Master_Skill_Name__c',
    'TR1__Skills__c.TR1__Duration_for_Job_Skill__c',
    'TR1__Skills__c.TR1__Level__c'
];

const SKILLS_ID = 'Generated_Skills_List';

export default class JobAdGenerator extends LightningElement {
    @api recordId;
   
    // UI State
    isMetadataOpen = false;
    isIncludeFieldsOpen = false;
    isAdvancedOpen = false;
    isGenerating = false;
    loadingJobData = true;
    errorMessage = '';
    isEditMode = false;
originalJobDescription;
    
    // Form State
    language = 'en';
    country = 'netherlands';
    brand = 'randstad';
    jobTitle = '';
    jobDescription = '';
    jobCountryCode = '';
    
    // Advanced Options
    length = '';
    formality = '';
    urgency = '';
    anonymized = true;
    toneOfVoice = '';
    
    @track selectedStructures = [];
    @track availableFields = []; 
    @track selectedFields = []; 
    
    // Result State
    generatedJobAd = '';
    conversationId = '';
    messageId = '';
    
    // Data Storage
    jobRecord;
    jobSkills = [];
    worksiteAddress = {};
    
    availableFieldsMap = {};

    get languageOptions() {
        return [
            { label: 'English', value: 'en' },
            { label: 'Dutch', value: 'nl' },
            { label: 'French', value: 'fr' },
            { label: 'German', value: 'de' },
            { label: 'Spanish', value: 'es' }
        ];
    }
    
    get brandOptions() {
        return [{ label: 'randstad', value: 'randstad' }];
    }
    
    connectedCallback() {
        this.loadFieldsConfiguration();
        this.loadJobAddress();
    }

    // ============================================
    // DATA LOADING
    // ============================================

    loadFieldsConfiguration() {
        getFieldsConfig()
            .then(result => {
                this.availableFields = result.map(field => ({
                    ...field,
                    isSelected: false,
                    id: field.apiName
                }));
                
                this.availableFieldsMap = this.availableFields.reduce((acc, field) => {
                    acc[field.apiName] = field;
                    return acc;
                }, {});
            })
            .catch(error => {
                console.error('❌ Error loading fields config:', error);
                this.availableFields = [];
            });
    }

    loadJobAddress() {
        getJobAddress({ jobId: this.recordId })
            .then(result => {
                console.log('✅ Address from Apex:', JSON.stringify(result, null, 2));
                this.worksiteAddress = result || {
                    street: '', city: '', state: '', stateCode: '',
                    postalCode: '', country: '', countryCode: ''
                };
                
                // Auto-detect country
                if (this.worksiteAddress.country) { console.log(this.worksiteAddress.country);
                    this.country = this.detectCountry(this.worksiteAddress.country);
                  //  this.country = this.worksiteAddress.country;
                }
            })
            .catch(error => {
                console.error('❌ Address load failed:', error);
                this.worksiteAddress = {
                    street: '', city: '', state: '', stateCode: '',
                    postalCode: '', country: '', countryCode: ''
                };
            });
    }

    @wire(getRecord, { recordId: '$recordId', fields: JOB_FIELDS })
    wiredJob({ data, error }) {
        if (data) {
            this.jobRecord = data;
            this.processJobData(data);
            this.loadingJobData = false;
            
        } else if (error) {
            console.error('❌ Job load failed:', JSON.stringify(error, null, 2));
            this.handleError('Failed to load job data', error);
            this.loadingJobData = false;
        }
    }

    processJobData(data) {
        this.jobTitle = getFieldValue(data, JOB_NAME) || '';
        this.jobCountryCode = getFieldValue(data, JOB_COUNTRY) || '';
        
        const desc = getFieldValue(data, JOB_DESC);
        const resp = getFieldValue(data, JOB_RESP);
        this.jobDescription = [desc, resp].filter(Boolean).join('\n\n');
    }
    get sanitizedJobDescription() {
    if (!this.jobDescription) {
        return '';
    }

    return this.jobDescription
        .replace(/<br\s*\/?>/gi, '\n')
        .replace(/<\/p>/gi, '\n')
        .replace(/<\/?[^>]+(>|$)/g, '')
        .replace(/&nbsp;/gi, ' ')
        .trim();
}

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'TR1__Skills__r',
        fields: SKILLS_FIELDS
    })
    wiredSkills({ error, data }) {
        if (data) {
            this.jobSkills = data.records.map(record => {
                const fields = record.fields;
                const masterSkill = fields.TR1__Master_Skill__r?.value;
                const skillName = masterSkill?.fields?.TR1__Master_Skill_Name__c?.value || 'Skill';
                const code = fields.TR1__Skill_Code__c?.value ? `(${fields.TR1__Skill_Code__c.value})` : '';
                
                const extras = [];
                if (fields.TR1__Level__c?.value) extras.push(`Level: ${fields.TR1__Level__c.value}`);
                if (fields.TR1__Duration_for_Job_Skill__c?.value) extras.push(`Duration: ${fields.TR1__Duration_for_Job_Skill__c.value}`);
                
                const extraText = extras.length > 0 ? ` - ${extras.join(', ')}` : '';
                return `${skillName} ${code}${extraText}`;
            });
        } else if (error) {
            console.error('❌ Skills load error', error);
            this.jobSkills = [];
        }
    }

    // ============================================
    // LOGIC BUILDERS
    // ============================================
buildIntakeNotes() {
    let notes = `Job Title: ${this.jobTitle} `; // Changed \n\n to a space

    const accountName = getFieldValue(this.jobRecord, JOB_ACCOUNT);
    if (accountName && !this.anonymized) {
        notes += `Client Name: ${accountName} `; // Changed \n\n to a space
    }

    if (this.jobDescription) {
        notes += `Description: ${this.stripHtmlTags(this.jobDescription)} `; // Removed \n and \n\n
    }

    // Add location from worksite address
    if (this.worksiteAddress.city || this.worksiteAddress.country) {
        const locationParts = [];
        if (this.worksiteAddress.city) locationParts.push(this.worksiteAddress.city);
        if (this.worksiteAddress.state) locationParts.push(this.worksiteAddress.state);
        if (this.worksiteAddress.country) locationParts.push(this.worksiteAddress.country);

        if (locationParts.length > 0) {
            notes += `Job Location: ${locationParts.join(', ')} `; // Changed \n\n to a space
        }
    }

    const selectedFieldsText = this.buildSelectedFieldsText();
    if (selectedFieldsText) {
        // Assuming buildSelectedFieldsText might return internal newlines, 
        // you may want to .replace(/\n/g, ' ') here as well.
        notes += selectedFieldsText.replace(/\n/g, ' ') + ' '; 
    }

    const instructions = this.buildAdInstructions();
    if (instructions) {
        notes += instructions.replace(/\n/g, ' '); 
    }

    console.log('📝 Intake notes:', notes.trim());
    return notes.trim();
}
    buildIntakeNotesbackup() {
        let notes = `Job Title: ${this.jobTitle}\n\n`;
        
        const accountName = getFieldValue(this.jobRecord, JOB_ACCOUNT);
        if (accountName && !this.anonymized) {
            notes += `Client Name: ${accountName}\n\n`;
        }
        
        if (this.jobDescription) {
            notes += `Description:\n${this.jobDescription}\n\n`;
        }
        
        // Add location from worksite address
        if (this.worksiteAddress.city || this.worksiteAddress.country) {
            const locationParts = [];
            if (this.worksiteAddress.city) locationParts.push(this.worksiteAddress.city);
            if (this.worksiteAddress.state) locationParts.push(this.worksiteAddress.state);
            if (this.worksiteAddress.country) locationParts.push(this.worksiteAddress.country);
            
            if (locationParts.length > 0) {
                notes += `Job Location: ${locationParts.join(', ')}\n\n`;
            }
        }
        
        const selectedFieldsText = this.buildSelectedFieldsText();
        if (selectedFieldsText) {
            notes += selectedFieldsText + '\n\n';
        }
        
        const instructions = this.buildAdInstructions();
        if (instructions) {
            notes += instructions + '\n\n';
        }
        
        console.log('📝 Intake notes:', notes);
        return notes;
    }
enableEditMode() {
    this.originalJobDescription = this.jobDescription;
    this.isEditMode = true;
}
handleCancel() {
    this.jobDescription = this.originalJobDescription;
    this.isEditMode = false;
}

handleSave() {
    // Save logic (Apex / LDS / Flow)
    this.isEditMode = false;
}
    buildSelectedFieldsText() {
        if (!this.selectedFields.length || !this.jobRecord?.fields) return '';

        return this.selectedFields
            .map(apiName => {
                const fieldConfig = this.availableFieldsMap[apiName];
                if (!fieldConfig) return null;

                if (apiName === SKILLS_ID) {
                    return this.jobSkills.length > 0 
                        ? `${fieldConfig.label}: ${this.jobSkills.join(' | ')}` 
                        : null;
                }

                const fieldData = this.jobRecord.fields[apiName];
                if (fieldData && fieldData.value) {
                    return `${fieldConfig.label}: ${fieldData.value}`;
                }
                return null;
            })
            .filter(Boolean)
            .join('\n');
    }

    buildAdInstructions() {
        const parts = [];
        if (this.length) parts.push(`Length: ${this.length}`);
        if (this.formality) parts.push(`Formality: ${this.formality}`);
        if (this.urgency) parts.push(`Urgency: ${this.urgency}`);
        if (this.toneOfVoice) parts.push(`Tone of Voice: ${this.toneOfVoice}`);
        if (this.anonymized) parts.push('Remove client name from ad');
        
        if (this.selectedStructures.length > 0) {
            parts.push(`Structure Requirements: ${this.selectedStructures.join(', ')}`);
        }
        
        return parts.length > 0 ? 'Ad Requirements: ' + parts.join(' | ') + '.' : '';
    }

    // ============================================
    // ACTIONS
    // ============================================

    handleGenerateJobAd() {
        if (!this.validateForm()) return;

        this.isGenerating = true;
        this.errorMessage = '';
        this.generatedJobAd = '';

        const requestData = {
            jobRecordId: this.recordId,
            intake_notes: this.buildIntakeNotes(),
            language: this.language,
            country: this.country,
            brand: this.brand
        };

        generateJobAd({ requestData }) 
            .then(result => {
                this.handleApiSuccess(result);
            })
            .catch(error => {
                this.handleApiError(error);
            })
            .finally(() => {
                this.isGenerating = false;
            });
    }

    handleApiSuccess(response) {
        this.conversationId = response.conversation_id || '';
        this.messageId = response.message_id || '';
        
        const rawAd = response.content?.job_ad || '';
        this.generatedJobAd = rawAd
            .replace(/\{\{.*?\}\}/g, '')
            .replace(/\n\s*\n/g, '\n\n');

        this.showToast('Success', 'Job ad generated successfully!', 'success');
    }

    handleCopyToClipboard() {
        if (!this.generatedJobAd) return;
        
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(this.generatedJobAd)
                .then(() => this.showToast('Success', 'Copied to clipboard!', 'success'))
                .catch(() => this.showToast('Error', 'Copy failed', 'error'));
        } else {
            const textarea = document.createElement('textarea');
            textarea.value = this.generatedJobAd;
            textarea.style.position = 'fixed';
            textarea.style.opacity = '0';
            document.body.appendChild(textarea);
            textarea.select();
            try {
                document.execCommand('copy');
                this.showToast('Success', 'Copied!', 'success');
            } catch (err) {
                this.showToast('Error', 'Copy failed', 'error');
            }
            document.body.removeChild(textarea);
        }
    }

    handleSaveToJob() {
        if (!this.generatedJobAd) return;

        const fields = {
            Id: this.recordId,
            Generated_Job_Ad__c: this.generatedJobAd
        };

        updateRecord({ fields })
            .then(() => {
                this.showToast('Success', 'Saved to Job record!', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'Failed to save', 'error');
            });
    }
    get jobDescriptionForEdit() {
    return this.isEditMode
        ? this.stripHtmlTags(this.jobDescription)
        : this.jobDescription;
}

    // ============================================
    // UTILITIES
    // ============================================

    stripHtmlTags(html) {
    if (!html) {
        return '';
    }

    // Remove HTML tags
    return html
        .replace(/<\/?[^>]+(>|$)/g, '') // remove tags
        .replace(/&nbsp;/gi, ' ')       // normalize spaces
        .trim();
}

    validateForm() {
        if (!this.jobTitle || !this.jobDescription) {
            this.showToast('Error', 'Please fill in job title and description', 'error');
            return false;
        }
        return true;
    }

    handleFieldToggle(event) {
        const fieldApiName = event.currentTarget.dataset.field;
        const field = this.availableFields.find(f => f.apiName === fieldApiName);
        
        if (field) {
            field.isSelected = !field.isSelected;
            
            if (field.isSelected) {
                this.selectedFields = [...this.selectedFields, fieldApiName];
            } else {
                this.selectedFields = this.selectedFields.filter(f => f !== fieldApiName);
            }
            this.availableFields = [...this.availableFields];
        }
    }
    
    handleLanguageChange(e) { this.language = e.detail.value; }
    handleBrandChange(e) { this.brand = e.detail.value; }
    handleCountryChange(e) { this.country = e.detail.value; }
    handleJobTitleChange(e) { this.jobTitle = e.target.value; }
    handleJobDescriptionChange(e) { this.jobDescription = e.target.value; }
    handleToneChange(e) { this.toneOfVoice = e.detail.value; }
    handleAnonymizedChange(e) { this.anonymized = e.target.checked; }
    
    handleIncludeFieldsToggle() { this.isIncludeFieldsOpen = !this.isIncludeFieldsOpen; }
    handleAdvancedToggle() { this.isAdvancedOpen = !this.isAdvancedOpen; }
    handleMetadataToggle() { this.isMetadataOpen = !this.isMetadataOpen; }

    handleOptionSelect(event) {
        const type = event.target.dataset.type;
        const value = event.target.dataset.value;
        if (type === 'length') this.length = value;
        else if (type === 'formality') this.formality = value;
        else if (type === 'urgency') this.urgency = value;
    }

    handleStructureToggle(event) {
        const value = event.target.dataset.value;
        if (this.selectedStructures.includes(value)) {
            this.selectedStructures = this.selectedStructures.filter(item => item !== value);
        } else {
            this.selectedStructures = [...this.selectedStructures, value];
        }
    }

    detectCountry(location) {
        const lower = (location || '').toLowerCase();
        const countryMap = {
            'netherlands': ['netherland', 'amsterdam', 'rotterdam', 'utrecht'],
            'belgium': ['belgium', 'brussels', 'antwerp', 'ghent'],
            'france': ['france', 'paris', 'lyon', 'marseille'],
            'germany': ['germany', 'berlin', 'munich', 'hamburg'],
            'spain': ['spain', 'madrid', 'barcelona', 'valencia'],
            'united_kingdom': ['uk', 'london', 'manchester', 'birmingham'] 
        };
        
        for (const [country, keywords] of Object.entries(countryMap)) {
            if (keywords.some(k => lower.includes(k))) return country;
        }
        return this.country;
    }

    handleError(message, error) {
        this.errorMessage = error?.body?.message || message;
        this.showToast('Error', this.errorMessage, 'error');
    }
    
    handleApiError(error) {
        this.handleError('Generation failed', error);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    
    get buttonLabel() { return this.isGenerating ? 'Generating...' : 'Generate Ad'; }
    get includeFieldsSectionClass() { return this.isIncludeFieldsOpen ? 'slds-section slds-is-open' : 'slds-section slds-is-closed'; }
    get includeFieldsTitle() { return `Include Fields (${this.selectedFields.length} selected)`; }
    get hasAvailableFields() { return this.availableFields.length > 0; }
    get activeFields() { return this.availableFields.filter(f => f.isActive); }
    get advancedSectionClass() { return this.isAdvancedOpen ? 'slds-section slds-is-open slds-m-top_medium' : 'slds-section slds-is-closed slds-m-top_medium'; }
    get metadataIconClass() { return this.isMetadataOpen ? 'meta-icon open' : 'meta-icon'; }
    
    get lengthOptions() { return this._buildOptions(['Summary', 'Concise', 'Short', 'Long', 'Elaborate'], this.length, 'length'); }
    get formalityOptions() { return this._buildOptions(['Highly Informal', 'Informal', 'Formal', 'Highly Formal'], this.formality, 'formality'); }
    get urgencyOptions() { return this._buildOptions(['Proactive', 'Medium', 'High', 'Urgent'], this.urgency, 'urgency'); }
    
    get toneOfVoiceOptions() {
        return ['Professional and Formal', 'Friendly and Approachable', 'Enthusiastic and Energetic', 
                'Creative and Innovative', 'Empowering and Motivational', 'Informative and Educational']
                .map(v => ({ label: v, value: v }));
    }
    
    get structureOptions() {
        return [
            'Modify the Paragraph Length', 'Adjust the Heading Structure', 'Incorporate Subsections',
            'Include emoticons', 'Use Bulleted or Numbered Lists', 'Provide Clear Call-to-Action'
        ].map(opt => ({
            label: opt, value: opt,
            class: this.selectedStructures.includes(opt) ? 'active' : ''
        }));
    }

    _buildOptions(labels, currentValue, type) {
        return labels.map(label => {
            const value = label.toLowerCase().replace(/ /g, '_');
            return {
                label, value,
                class: currentValue === value ? 'active' : ''
            };
        });
    }
}