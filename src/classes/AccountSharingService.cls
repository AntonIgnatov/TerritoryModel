/**
 * Created by venzor on 4/7/2019.
 */

public with sharing class AccountSharingService {

    public static void shareNewAccounts(List<Account> newAccounts) {
        List<Account> accountsToShare = new List<Account>();
        for (Account acc : newAccounts) {
            if (acc.Territory__c != null) {
                accountsToShare.add(acc);
            }
        }
        Set<Id> accountsTerrIds = new Set<Id>();
        for (Account acc : accountsToShare) {
            accountsTerrIds.add(acc.Territory__c);
        }
        Map<Id, Set<Id>> usersIdsToShare = TerritoryHierarchyService.getUsersIdsOnRisingHierarchy(accountsTerrIds);
        SharingService.shareNewAccounts(usersIdsToShare, accountsToShare);

    }

    public static void separateAccountsToShare(Map<Id, Account> accBeforeUpdate, Map<Id, Account> accAfterUpdate) {
        List<Account> accToShare = new List<Account>();
        List<Account> accToUnshare = new List<Account>();
        Set<Id> newTerIds = new Set<Id>();
        Set<Id> oldTerIds = new Set<Id>();
        for (Id accId : accAfterUpdate.keySet()) {
            if (accAfterUpdate.get(accId).Territory__c != null &&
                    accBeforeUpdate.get(accId).Territory__c != null &&
                    !accBeforeUpdate.get(accId).Territory__c.equals(accAfterUpdate.get(accId).Territory__c)) {

                    accToShare.add(accAfterUpdate.get(accId));
                    newTerIds.add(accAfterUpdate.get(accId).Territory__c);

                    accToUnshare.add(accBeforeUpdate.get(accId));
                    oldTerIds.add(accBeforeUpdate.get(accId).Territory__c);
            }
        }

        SharingService.unshareAccounts(accToUnshare);
        Map<Id, Set<Id>> usersIdsToShare = TerritoryHierarchyService.getUsersIdsOnRisingHierarchy(newTerIds);
        SharingService.shareNewAccounts(usersIdsToShare, accToShare);


    }
}