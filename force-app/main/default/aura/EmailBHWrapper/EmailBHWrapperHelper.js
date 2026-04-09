/**
 * @description       : Bullhorn Email Wrapper Helper
 * @author            : mhamdaoui@salesforce.com
 * @last modified on  : 07-15-2024
 * @last modified by  : Raga Viswanathan
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   04-04-2022   mhamdaoui@salesforce.com   Initial Version
 * 1.1   04-27-2022   Raga Viswanathan           Added Logic to send status to atsSubStage & Removed Apex Update
 * 1.1   07-12-2022   Raga Viswanathan           CITATS-1210
 * 1.2   10-10-2022   Raga Viswanathan           CITATS-1687
**/
({
    // dynamically creates a modal window with TR1:eML_Email component as a body with the help of lightning:overlayLibrary
    openModalSubmitWithEmail: function(component, event, helper, params) {
        let prefix = 'TR1';
        let overlayComponents = [];

        overlayComponents.push( // Configure modal icon
            [
                'lightning:icon',
                {
                    'iconName': 'utility:task',
                    'size': 'small',
                    'class': 'reject-header-icon'
                }
            ]
        );

        overlayComponents.push( // Configure modal title name
            [
                'lightning:formattedText',
                {
                    'value': params.jobName,
                    'class': 'slds-m-left_x-small slds-text-heading_medium slds-hyphenate mass-email-header-align'
                }
            ]
        );

        overlayComponents.push( // Configure the new email component
            [
                prefix + ':eML_Email',
                {
                    'aura:id': 'ATS_SubmittalEmail',
                    // If the scheduleId (TR1__Send_Out_Schedule__c Id ) is present then pass it to the modal, else pass the application Id instead
                    'recordId': params.scheduleId ? params.scheduleId : component.get('v.recordId'),
                    'applicationIdsForResumes': component.get('v.appIds'),
                    'contactIdsForResumes':  component.get('v.conIdsList'),
                    'showResumeSection' : component.get('v.defaultResumeAttachment'),
                    'initialToList' : params.initialToList,
                    'referenceField' : prefix + '__Account__c',
                    'required' : true,
                    'isVisibleCcButton' : true,
                    'isVisibleBccButton' : true,
                    'allowEmailFormatCc' : true,
                    'allowEmailFormatBcc' : true,
                    'onclosemodal': component.getReference('c.closeEmailModal'),
                    'searchUsersTo' : true,
                    'searchUsersCc' : true,
                    'searchUsersBcc' : true,
                    'showHelpText' : true,
                    'showSuccessToast' : false,
                    'emailPageType' :  params.emailPageType ? params.emailPageType : component.get('v.emailPageType'),
                    'templateId' : component.get('v.templateId')
                }
            ]
        );

        overlayComponents.push( // Configure the modal cancel button action
            [
                'lightning:button',
                {
                    'name': 'Cancel',
                    'label': $A.get('$Label.TR1.Cancel'),
                    'onclick': component.getReference('c.closeEmailModal')
                }
            ]
        );

        overlayComponents.push( // Configure the modal send button action
            [
                'lightning:button',
                {
                    'name': 'Send',
                    'variant': 'brand',
                    'label': $A.get('$Label.TR1.Send'),
                    'onclick': component.getReference('c.sendSubmitWithEmail')
                }
            ]
        );

        if (overlayComponents.length > 0) {
            helper.createComponents
            (component, helper, overlayComponents,
                function(component, helper, components) {
                    component.find('submittalOverlayLib').showCustomModal({
                        header: [components[0], components[1]],
                        body: components[2],
                        footer: [components[3], components[4]],
                        showCloseButton: true,
                        cssClass: 'slds-modal_large'
                    }).then(
                        $A.getCallback (
                            function (overlay) {
                                component.set('v.submittalOverlayLib', overlay);
                            }
                        )
                    );
                }, null
            );
        }
    },
    
    // closes Submittal Email modal window
    closeEmailModal: function(component, event, helper) {
        let overlay = component.get('v.submittalOverlayLib')[0];
        if (overlay) {
            setTimeout(function() {
                overlay.close();
            }, 50);
        }
    },
    
    // handles dynamic creation of multiple components
    createComponents:function(component, helper, components, successCallback, scope) {
        $A.createComponents(components,
            function(components, status, errorMessage){
                if (status === "SUCCESS") {
                    successCallback(component, helper, components, scope);
                }
                else if (status === "INCOMPLETE") {
                    helper.showToast("No response from server or client is offline.", "error")
                }
                else if (status === "ERROR") {
                    helper.showToast("Error: " + errorMessage, "error")
                }
            }
        );
    },

    // shows success message
    notifySuccess: function(message) {
        this.showToast(message, 'success', 'dismissible');
    },
	
	// fires toast
    showToast: function(message, type, mode) {
        let toastEvent = $A.get('e.force:showToast');

        toastEvent.setParams({
            mode: mode != '' ? mode : 'sticky',
            message: message,
            type: type != '' ? type : 'success'
        });
        toastEvent.fire();
    },
	
	// notifies about an error
    notifyError: function(message) {
        if (Array.isArray(message)) {
            if (message.length > 0) {
                message = message[0];
            }
        }
        if (typeof message === 'object') {
            message = message.message;
        }
        if (message) {
            this.showToast(message, 'error', 'dismissible');
        }
    },

    //  refreshes the ATS using the TR1 global event - ATS_Application_Update_Event
    refreshView: function (component) {
        if (component && component.isValid()) {
            let actionEvent = component.getEvent('notifyUpdateEvent');
            actionEvent.setParams({
                'suppressMessage': true
            });
            actionEvent.fire();
         }
    },
    //  Send Status to ATS Sub Stage
    changeSubStage: function(component, emailData, templateId){
        try {
            var payload = {
                status: {
                    // Check whether the email is sent using the default template Id
                    sentUsingDefaultTemplate: templateId?emailData.templateId === templateId : true,
                    value: "EmailSent",
                    channel: "ATSStageChange",
                    source: "Aura"
                }
            };
            //component.find("ATSStageMessage").publish(payload);
        } catch (error) {
            console.log(`Error—${error}`);
        }
    },
    // for the new email component, when the send button is clicked, this is the method called
    sendSubmitWithEmailHelper: function(component, event, helper, stage) {
        let ATS_MassEmail = component.find('ATS_SubmittalEmail');
        if (ATS_MassEmail) {
            let massEmailComponent = [].concat(ATS_MassEmail)[0];
            massEmailComponent.sendMailWithEmailData(helper.sendSubmitWithEmailCallback, [component, helper, component.get('v.templateId')]);
        }
    },

    // when the send is finished, this callback method is called. Here you can add any logic you'd like to include on Submit after sending an email
    sendSubmitWithEmailCallback: function(component, helper, templateId, emailData) {
        if (component && helper && emailData) {
            helper.notifySuccess($A.get("$Label.TR1.ATSv2_Records_saveMsg"), helper);
            helper.changeSubStage(component, emailData, templateId);
            helper.refreshView(component);   
        }
    }
})