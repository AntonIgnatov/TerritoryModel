/**
 * Created by Diz-19 on 27.03.2019.
 */

trigger TerritoryTrigger on Territory__c (before insert, before update ) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            TerritoryTriggerHandler.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            TerritoryTriggerHandler.beforeUpdate(Trigger.new);
        }
    }

}