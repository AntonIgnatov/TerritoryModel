/**
 * Created by Diz-19 on 02.04.2019.
 */

public with sharing class ReferenceTriggerHandler {

    public static void beforeInsert(List<Reference__c> newReferences) {
        ReferenceCheckService.addErrorsToDuplicate(newReferences);
    }

    public static void afterInsert(List<Reference__c> newReferences) {
        ContactSharingService.shareContacts(newReferences);
    }

    public static void afterDelete(List<Reference__c> deletedReferences) {
        ContactSharingService.unshareContacts(deletedReferences);
    }
}