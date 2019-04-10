/**
 * Created by Diz-19 on 08.04.2019.
 */

public with sharing class ContactSharingService {

    public static void shareContacts(List<Reference__c> references){
        Set<Id> contactsToShareIds = new Set<Id>();
        for(Reference__c reference : references){
            contactsToShareIds.add(reference.Contact__c);
        }
        SharingService.shareContacts(contactsToShareIds);
    }

    public static void unshareContacts(List<Reference__c> references){
        Set<Id> contactsToShareIds = new Set<Id>();
        for(Reference__c reference : references){
            contactsToShareIds.add(reference.Contact__c);
        }
        SharingService.unshareContacts(contactsToShareIds);
    }

}