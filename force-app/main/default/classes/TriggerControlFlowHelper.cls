public class TriggerControlFlowHelper {
    @InvocableMethod(label='Set Trigger Bypass For Flow')
    public static void setBypass(List<String> flowLabels) {
        for (String label : flowLabels) {
            TriggerBypassUtil.bypassedFlows.add(label);
            system.debug('label'+label);
        }
    }
}