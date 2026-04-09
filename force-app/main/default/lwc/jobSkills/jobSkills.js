import { LightningElement, api, wire, track } from 'lwc';
import getSkills from '@salesforce/apex/JobFunctionSkillController.getSkills';
import upsertJobSkills from '@salesforce/apex/JobFunctionSkillController.upsertJobSkills';
import deleteJobSkills from '@salesforce/apex/JobFunctionSkillController.deleteJobSkills';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import SKILL_OBJECT from '@salesforce/schema/TR1__Skills__c';
import LEVEL_FIELD from '@salesforce/schema/TR1__Skills__c.TR1__Level__c';
import DURATION_FIELD from '@salesforce/schema/TR1__Skills__c.TR1__Duration_for_Job_Skill__c';

export default class JobFormWithSkills extends LightningElement {
    @api recordId;
    @track jobFunction;
    @track suggestedSkills = [];
    @track skills = [];
    @track jobSkills = [];
    @track selectedSkills = [];
    @track existingSkillIds = new Set();
    @track showFooter = false;
    hasUnsavedChanges = false;
    error;
    draftValues = [];
    //refreshKey=0;
    wiredJobSkillsResult;
    skillsRawData;
    @track isProcessing = false; // Spinner is hidden by default    
    columns = [
        { label: 'Skill Code', fieldName: 'skillCode' },
        { label: 'Master Skill', fieldName: 'masterSkill' },
        {
            label: 'Level',
            fieldName: 'level',
            type: 'customCombobox',
            editable: true,
            typeAttributes: {
                options: { fieldName: 'levelOptions' },
                value: { fieldName: 'level' }, 
                rowId: { fieldName: 'Id' },
                fieldName: 'level'
            }
        },
        {
            label: 'Duration',
            fieldName: 'duration',
            type: 'customCombobox',
            editable: true,
            typeAttributes: {
                options: { fieldName: 'durationOptions' },
                value: { fieldName: 'duration' }, 
                rowId: { fieldName: 'Id' },
                fieldName: 'duration'
            }
        }
    ];

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'TR1__Skills__r',
        fields: [
            'TR1__Skills__c.Id',
            'TR1__Skills__c.TR1__Skill_Code__c',
            'TR1__Skills__c.TR1__Master_Skill_Name__c',
            'TR1__Skills__c.TR1__Level__c',
            'TR1__Skills__c.TR1__Duration_for_Job_Skill__c'
        ],
        //refreshKey: '$refreshKey'      
    })
    wiredJobSkills(result) {
        this.isProcessing=true;
        this.wiredJobSkillsResult = result;
        if (result.data) {
            const rows = result.data.records.map(r => {
                const f = r.fields;
                const row = {
                    Id: f.Id.value,
                    skillCode: f.TR1__Skill_Code__c.value,
                    masterSkill: f.TR1__Master_Skill_Name__c.value,
                    level: f.TR1__Level__c?.value || '',
                    duration: f.TR1__Duration_for_Job_Skill__c?.value || '',
                    levelOptions: this.levelOptions,
                    durationOptions: this.durationOptions
                };
                this.existingSkillIds.add(row.skillCode);
                
                return row;
            });
            this.selectedSkills = [...rows];
        } else if (result.error) {
            this.isProcessing=false;
            console.error('Error loading job skills', result.error);
        }
        this.isProcessing=false;
    }

    @track levelOptions = [];
@track durationOptions = [];

@wire(getObjectInfo, { objectApiName: SKILL_OBJECT })
objectInfo;

@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LEVEL_FIELD })
wiredLevelValues({ data, error }) {
    
    if (data) {
        this.levelOptions = data.values.map(opt => ({
            label: opt.label,
            value: opt.value
        }));
        this.checkAndApplyPicklists();

    } else if (error) {
        console.error('Error loading level picklist values', error);
    }
    
}

@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: DURATION_FIELD })
wiredDurationValues({ data, error }) {
    
    if (data) {
        this.durationOptions = data.values.map(opt => ({
            label: opt.label,
            value: opt.value
        }));
        this.checkAndApplyPicklists();

    } else if (error) {
        console.error('Error loading duration picklist values', error);
    }
    
}

    connectedCallback() {
        this.isProcessing=true;
        this.handleGetSkills();
       
    }

    handleJobFunctionChange(event) {
        this.jobFunction = event.detail.value;
    }

    handleGetSkills() {
        this.error = null;
        getSkills({ jobId: this.recordId })
            .then(result => {
                this.skills = result
                    .sort((a, b) => b.Score - a.Score)
                    .map(skill => ({
                        Id: skill.Id,
                        Description: skill.Description,
                        ScoreFormatted: `Score: ${parseFloat(skill.Score).toFixed(3)}`
                    }))
                    .filter(skill => !this.existingSkillIds.has(skill.Id)); // filter out already selected
                    this.isProcessing=false;
            })
            .catch(err => {
                this.error = err?.body?.message || 'Error retrieving skills.';
                this.skills = [];
                this.isProcessing=false;
            });
    }

    handleClickOnPill(event) {
        const skillId = event.target.name;
        const index = this.skills.findIndex(skill => skill.Id === skillId);
        if (index !== -1 && !this.existingSkillIds.has(skillId)) {
            const selected = this.skills[index];

            this.selectedSkills = [
                ...this.selectedSkills,
                {
                    skillCode: selected.Id,
                    masterSkill: selected.Description,
                    level: '',
                    duration: '',
                   jobCode: this.recordId,
                   levelOptions: this.levelOptions,
                    durationOptions: this.durationOptions
                }
            ];
            this.existingSkillIds.add(skillId);
            const newRowIndex = this.selectedSkills.length==null?0:this.selectedSkills.length-1;
            this.draftValues=[...this.draftValues,{
                    Id:'row-'+newRowIndex,
                    skillCode: selected.Id,
                    masterSkill: selected.Description,
                    level: '',
                    duration: '',
                   jobCode: this.recordId
                }];
                console.log(JSON.stringify(this.draftValues));
            this.skills.splice(index, 1);
            this.skills = [...this.skills];
            this.hasUnsavedChanges = true;
            this.showFooter = true;
        }
    }

handleSaveSkills(event) {
    // Filter skills that have skillCode (mandatory)
    this.isProcessing=true;
    console.log(JSON.stringify(event.detail.draftValues));
    const validRowsToSave = this.selectedSkills.filter(row => row.skillCode);

    if (validRowsToSave.length === 0) {
        return; // Nothing to save
    }

 const skillsToUpsert = validRowsToSave.map(row => ({
    Id: row.Id || null,
    skillCode: row.skillCode,
    level: row.level || '',
    duration: row.duration || '',
    jobCode: this.recordId
}));
    const skillsJsonString = JSON.stringify(skillsToUpsert);
    const jobId = this.recordId;

    upsertJobSkills({ skillsJson: JSON.stringify(event.detail.draftValues),jobId:jobId}) 
        .then(() => {
            this.showToast('Success', 'Skills saved successfully', 'success');
            this.draftValues = [];
            //this.refreshKey++;
            this.isProcessing=false;
 
        })
        .catch(error => {
            console.error('Error saving skills:', error);
            this.showToast('Error', 'Failed to save skills: ' + (error.body?.message || error.message), 'error');
            this.isProcessing=false;
        });
    
}

showToast(title, message, variant) {
    const evt = new ShowToastEvent({
        title,
        message,
        variant,
    });
    this.dispatchEvent(evt);
}
get picklistsReady() {
    return this.levelOptions.length > 0 && this.durationOptions.length > 0;
}
rehydratePicklistOptions() {
    this.selectedSkills = this.selectedSkills.map(row => ({
        ...row,
        levelOptions: this.levelOptions,
        durationOptions: this.durationOptions
    }));
}
checkAndApplyPicklists() {
    if (this.picklistsReady) {
        this.rehydratePicklistOptions();
    }
}

@track showNewSkillModal = false;

handleNewSkillClick() {
    this.showNewSkillModal = true;
}

handleCancelNewSkill() {
    this.showNewSkillModal = false;
}

// Refresh the table after skill is created
handleSkillCreateSuccess(event) {
    this.showNewSkillModal = false;
    //this.refreshKey++;
    this.showToast('Success', 'New skill created successfully.', 'success');
        return refreshApex(this.wiredJobSkillsResult);
    //this.refreshKey++; // Triggers refresh of the related list
}

/*Bhuvana Changes*/
 get isRemoveButtonDisabled() {
        return this.draftValues.length > 0;
    }
    handleRowSelection(event) {
        this._selectedRowIds = event.detail.selectedRows.map(row => row.Id);
    }
    async handleRemoveSelectedRows() {
    if (!this._selectedRowIds || this._selectedRowIds.length === 0) {
        this.showToast('Info', 'Please select rows to remove.', 'info');
        return;
    }

    this.isProcessing = true;
    const selectedIds = new Set(this._selectedRowIds);
    const dbIdsToDelete = this._selectedRowIds.filter(id => id && !id.startsWith('row-'));

    try {
        if (dbIdsToDelete.length > 0) {
            await deleteJobSkills({ skillIds: dbIdsToDelete });
        }

        this.selectedSkills = this.selectedSkills.filter(skill => !selectedIds.has(skill.Id));

        this.existingSkillIds = new Set(this.selectedSkills.map(s => s.skillCode));

        this._selectedRowIds = [];
        this.showToast('Success', 'Selected skills were deleted.', 'success');

    } catch (error) {
        this.showToast('Error', `Failed to delete skills: ${error.body?.message || error.message}`, 'error');
    } finally {
        this.handleGetSkills();
        this.isProcessing = false;
    }
}

}