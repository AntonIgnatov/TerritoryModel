/**
 * Created by Diz-19 on 02.04.2019.
 */

trigger ReferenceTrigger on Reference__c (before insert, after insert, after delete ) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            ReferenceTriggerHandler.beforeInsert(Trigger.new);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            ReferenceTriggerHandler.afterInsert(Trigger.new);
        }
        if(Trigger.isDelete){
            ReferenceTriggerHandler.afterDelete(Trigger.old);
        }
    }

}