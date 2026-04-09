/**
 * @description       : Rejection Wrapper for BH Reject Talent Modal
 * @author            : mhamdaoui@salesforce.com
 * @last modified on  : 03-10-2022
 * @last modified by  : mhamdaoui@salesforce.com
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-09-2022   mhamdaoui@salesforce.com   Initial Version
 **/
({
    // Init appIds
    init: function(component, message, helper) {
        // Make sure component is always rendered on init
        component.set("v.appIds", []);

        var appIds = [].concat(component.get("v.recordId"));
        component.set("v.appIds", appIds);
    }
});