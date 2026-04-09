public class TriggerBypassUtil {
    public static Set<String> bypassedFlows = new Set<String>();

    public static Boolean shouldBypass(String flowLabel) {
        return bypassedFlows.contains(flowLabel);
    }
}