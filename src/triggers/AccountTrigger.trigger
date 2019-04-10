/**
 * Created by venzor on 4/7/2019.
 */

trigger AccountTrigger on Account (after insert, after update) {

    if (Trigger.isAfter) {
        If (Trigger.isInsert) {
            AccountTriggerHadler.afterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AccountTriggerHadler.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}