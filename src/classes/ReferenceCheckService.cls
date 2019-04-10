/**
 * Created by Diz-19 on 02.04.2019.
 */

public with sharing class ReferenceCheckService {

    public static void addErrorsToDuplicate(List<Reference__c> referencesBeforeInsert){
        DuplicateCheckService checker = new DuplicateCheckService(referencesBeforeInsert, 'Account__c', 'Contact__c');
        checker.markDuplicatedObjects();
    }
}