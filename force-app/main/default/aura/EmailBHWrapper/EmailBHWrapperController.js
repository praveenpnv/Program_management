/**
 * @description       : Bullhorn Email Wrapper Controller
 * @author            : mhamdaoui@salesforce.com
 * @last modified on  : 04-04-2022
 * @last modified by  : mhamdaoui@salesforce.com
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-07-2022   mhamdaoui@salesforce.com   Initial Version
 **/

({
    doInit: function (component, event, helper) {
        var appIds = [].concat(component.get('v.recordId'));
        if (appIds) {
            component.set("v.appIds", appIds);
            var action = component.get("c.getDetailsByApplicationIds");
            action.setParams({
                appIds: appIds,
                stage: component.get('v.stage')
            });

            action.setCallback(this, function (response) {
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    var submittalDetails = response.getReturnValue();
                    if (submittalDetails) {
                        component.set("v.conIdsList", submittalDetails.contIds);
                        component.set("v.jobId", submittalDetails.jobId);
                        component.set("v.defaultResumeAttachment", submittalDetails.defaultResumeAttachment);
                        switch (component.get('v.stage').trim()) {
                            case "Application":
                            case "Internal Interview":
                            case "Client Interview":
                            case "Offer":
                                component.set("v.initialToList", submittalDetails.contIds);
                                break;
                            case "Proposal to Client":
                                component.set("v.initialToList", submittalDetails.hiringManager);
                                break;
                            case "Submission":
                                component.set("v.initialToList", submittalDetails.clientContact);
                                break;
                        }

                        component.set("v.jobName", $A.get("$Label.TR1.ATSv2_Quick_Submit") + " " + submittalDetails.jobName);
                        component.set("v.templateId",submittalDetails.templateId);
                    }
                } else {
                    helper.showToast(response.getError(), "error", "dismissible");
                }
            });
            $A.enqueueAction(action);
            
        }
    },
    // Listen to LMS for opening the modal && gathers and populates all necessary attributes
    openModal: function (component, message, helper) {
        var openModal = message.getParam("modal") === component.get('v.stage').trim();
        if (openModal) {
            var params = {
                jobId: component.get("v.jobId"),
                appIds: component.get("v.appIds"),
                jobName: component.get("v.jobName"),
                initialToList: component.get("v.initialToList"),
                templateId: component.get("v.templateId"),
                scheduleId: message.getParam("recordId"),
                emailPageType: message.getParam("emailPageType")
            };
            if (component.isValid()) {
                helper.openModalSubmitWithEmail(component, event, helper, params);
            }
        }
    },

    // callback method which is run when the TR1 component sent an email
    sendSubmitWithEmail: function (component, event, helper) {
        var stage = component.get('v.stage');
        helper.sendSubmitWithEmailHelper(component, event, helper, stage);
    },

    // closes Submittal Email modal window
    closeEmailModal: function (component, event, helper) {
        helper.closeEmailModal(component, event, helper);
    }
});