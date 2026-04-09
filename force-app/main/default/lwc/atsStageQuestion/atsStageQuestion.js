import { LightningElement, track, wire, api } from 'lwc';
import getSelectedQuestions from '@salesforce/apex/QuestionDisplayController.getSelectedQuestions';
import saveResponses from '@salesforce/apex/QuestionDisplayController.saveResponses';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class JobPrescreening extends LightningElement {
    @track questions = [];
    @api recordId;
    @api applicationId;
    responses = [];
    groupedQuestions = [];
    picklistOptions ;

    booleanOptions = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' }
    ];

    @wire(getSelectedQuestions, { applicationId: '$recordId' })
    wiredQuestions({ error, data }) {
        if (data) {
             console.log('questions DAta' + JSON.stringify(data));
            const grouped = {};
            //this.groupedQuestions = Object.keys(data);
            this.questions = data.map(question => {
            const group = question.grouping;
            console.log('group' + group);
             if (!grouped[group]) {
                    grouped[group] = [];
                }
            console.log('group Data' + JSON.stringify(group));
                grouped[group].push({
                ...question,
                isText: question.responseType === 'Text',
                isPicklist: question.responseType === 'Picklist',
                isParagraph: question.responseType === 'Paragraph',
                isBoolean: question.responseType === 'Boolean',
                // Process ResponseOptions__c to generate options for combobox
                picklistOptions: this.getPicklistOptions(question.responseOptions),
               //isRequired:group === 'General' ,
                //responseValue:question.responseValue,
                
            });
            if (question.responseValue) {
                    this.responses[question.questionId] = question.responseValue;
                }
            });
            this.groupedQuestions = Object.keys(grouped).map(group => {
                return { groupName: group, questions: grouped[group] };
            });
            console.log('questions####' + JSON.stringify(this.groupedQuestions));

            

           
        } else if (error) {
            console.error('Error fetching selected questions', error);
        }
    }

    // Generate options for lightning-combobox from ResponseOptions__c field
    getPicklistOptions(responseOptions) {
        if (!responseOptions) {
            return [];
        }
        const options=[];
        responseOptions.split(";").forEach(opt => {
            options.push({
                 label: opt,
                 value: opt
            });
     
        });
        console.log('options'+options);
        return options;
          
    }

    handleInputChange(event) {
        const questionId = event.target.name;
        const value = event.target.value;
        console.log('questionId:'+questionId);
        this.groupedQuestions.forEach(group => {
            group.questions.forEach(question => {
               
                if (question.questionId === questionId) {
                     console.log('questionId>>>:'+question.questionId);
                    question.responseValue = value;
                    // Update the specific question
                }
            });
        });
        console.log('Updated groupedQuestions:', JSON.stringify(this.groupedQuestions));
    }
@api
     saveResponses() {
        const responsesToSave = [];

        // Prepare the data to be sent to Apex
        this.groupedQuestions.forEach(group => {
            group.questions.forEach(question => {
                if (question.responseValue) {
                    responsesToSave.push({
                        questionId: question.questionId,
                        responseValue: question.responseValue,
                        responseId:question.responseId,
                        applicationId:this.recordId
                    }); 
                }
            });
        })
        console.log('responsesToSave:', JSON.stringify(responsesToSave));
        saveResponses({ responses:responsesToSave})
            .then(() => {
               // this.showToast('Success', 'Response saved successfully.', 'success');
                this.responses={};
                this.dispatchEvent(new CustomEvent('responsesuccess', { detail: 'success' })); // Dispatch success event
            })
            .catch(error => {
                console.error('Error saving responses', error);
                this.dispatchEvent(new CustomEvent('responseerror', { detail: { message: error } })); // Dispatch error event
            });
    } 

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

}