/**
 * Created by venzor on 3/28/2019.
 */

trigger ContactTrigger on Contact (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ContactTriggerHandler.beforeInsert(Trigger.new);
        }
    }
}