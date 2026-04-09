/**
 * @description       : Custom Flow Footer Controller
 * @author            : mhamdaoui@salesforce.com
 * @last modified on  : 07-16-2024
 * @last modified by  : Raga Viswanathan
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-09-2022   mhamdaoui@salesforce.com   Initial Version
 * 2.0   04-26-2022   mhamdaoui@salesforce.com   CITATS-407 (CITATS-186)
 **/
({
    // Init handler
    init: function (cmp, event, helper) {
        helper.initHelper(cmp, event, helper);
    },

    // LMS Refresh
    atsRefresh: function (cmp, message, helper) {
        var actionEvent = cmp.getEvent("notifyUpdateEvent");

        if (message && message.getParam("recordId")) {
            actionEvent.setParams({
                suppressMessage: true
            });
            actionEvent.fire();
        }

        if (message && message.getParam("Action") && message.getParam("Button")) {
            if(message.getParam("Button") === "REJECT_TALENT") {
                // Make sure the modal rerender everytime since we don't have control over closing state
                cmp.set("v.showRejectionModal", false);
                cmp.set("v.showRejectionModal", true);
            }

            if(message.getParam("Button") === "CLOSE_MODAL") {
                var navigate = cmp.get('v.navigateFlow');
                navigate("NEXT");
                navigate("NEXT");


            }
        }
    },
});