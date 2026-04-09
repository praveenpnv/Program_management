/**
 * @description       : Custom Flow Footer Helper
 * @author            : mhamdaoui@salesforce.com
 * @last modified on  : 05-09-2022
 * @last modified by  : mhamdaoui@salesforce.com
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-09-2022   mhamdaoui@salesforce.com   Initial Version
 * 2.0   04-26-2022   mhamdaoui@salesforce.com   CITATS-407 (CITATS-186)
 **/
({
    initHelper: function (cmp, event, helper) {
        cmp.set("v.showRejectionModal", false);
    },
});