/**
 * Created by Diz-19 on 29.03.2019.
 */

trigger TerrUserTrigger on TerrUser__c (before delete, before insert, after insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            TerrUserTriggerHandler.beforInsert(Trigger.new);
        }
        if (Trigger.isDelete) {
            TerrUserTriggerHandler.beforDelete(Trigger.old);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            TerrUserTriggerHandler.afterInsert(Trigger.new);
        }
    }
}