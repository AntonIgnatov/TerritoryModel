/**
 * Created by venzor on 3/30/2019.
 */

public with sharing class SharingService {

    public static void shareAccountsByTerritory(Map<Id, Set<Id>> newRelationsToTerritories, Map<Id, Set<Id>> childToParentsTerriroties) {

        Map<Id, List<Account>> referencesOnTerritories = getAccountsOnTerritories(childToParentsTerriroties.keySet());

        Set<AccountShare> accountsToShare = new Set<AccountShare>();
        Set<ContactShare> contactsToShare = new Set<ContactShare>();

        for (Id terrWithReferences : referencesOnTerritories.keySet()) {
            for (Id asignedTerritoryId : childToParentsTerriroties.get(terrWithReferences)) {
                for (Id userId : newRelationsToTerritories.get(asignedTerritoryId)) {
                    for (Account acc : referencesOnTerritories.get(terrWithReferences)) {
                        accountsToShare.add(
                                new AccountShare(
                                        AccountId = acc.Id,
                                        UserOrGroupId = userId,
                                        AccountAccessLevel = 'Read',
                                        RowCause = 'Manual',
                                        OpportunityAccessLevel = 'Read'
                                ));
                        if (acc.References__r.size() != 0) {
                            for (Reference__c linkToContact : acc.References__r) {
                                contactsToShare.add(
                                        new ContactShare(
                                                ContactId = linkToContact.Contact__c,
                                                UserOrGroupId = userId,
                                                ContactAccessLevel = 'Read',
                                                RowCause = 'Manual'));
                            }
                        }

                    }
                }
            }
        }
        List<AccountShare> accountSharesToSave = new List<AccountShare>(accountsToShare);
        List<ContactShare> contactSharesToSave = new List<ContactShare>(contactsToShare);
        saveShareObject(accountSharesToSave, 'AccountId');
        saveShareObject(contactSharesToSave, 'ContactId');
    }

    public static void unshareAccByTerritory(Map<Id, Set<Id>> usersToTerritories) {
        Map<Id, Set<Id>> terrToUsers = MapConverter.changeMapDirection(usersToTerritories);
        List<Id> terrOnOperation = new List<Id>();
        for (Set<Id> terrIds : usersToTerritories.values()) {
            terrOnOperation.addAll(terrIds);
        }
        Map<Id, Set<Id>> childsOnHierarchy = TerritoryHierarchyService.getChildsAssociatedToParent(terrOnOperation);
        List<AccountShare> sharedAcc = [
                SELECT AccountId, Account.Territory__c, UserOrGroupId
                FROM AccountShare
                WHERE UserOrGroupId IN :usersToTerritories.keySet()
                AND AccountId IN (
                        SELECT Id
                        FROM Account
                        WHERE Territory__c IN :childsOnHierarchy.keySet()
                )
                AND RowCause = 'Manual'
        ];
        List<AccountShare> sharingToDelete = new List<AccountShare>();
        Set<Id> accIdsToUnshare = new Set<Id>();
        for (AccountShare shar : sharedAcc) {
            if (childsOnHierarchy.containsKey(shar.Account.Territory__c)) {
                for (Id topTerr : childsOnHierarchy.get(shar.Account.Territory__c)) {
                    if (terrToUsers.containsKey(topTerr)) {
                        for (Id user : terrToUsers.get(topTerr)) {
                            if (user.equals(shar.UserOrGroupId)) {
                                sharingToDelete.add(shar);
                                accIdsToUnshare.add(shar.AccountId);
                            }
                        }
                    }
                }
            }
        }

        delete sharingToDelete;
        Set<Id> contactsToUnshare = new Set<Id>();
        for (Account acc : [
                SELECT Id, (SELECT Contact__c FROM References__r)
                FROM Account
                WHERE Id IN :accIdsToUnshare
        ]) {
            for (Reference__c reference : acc.References__r) {
                contactsToUnshare.add(reference.Contact__c);
            }
        }
        unshareContacts(contactsToUnshare);

    }


    public static void shareNewAccounts(Map<Id, Set<Id>> usersIdsToShare, List<Account> accounts) {
        List<AccountShare> accountSharesToSave = new List<AccountShare>();
        List<ContactShare> contactSharesToSave = new List<ContactShare>();

        List<Account> accToShare = [
                SELECT Id, Territory__c, (
                        SELECT Contact__c
                        FROM References__r
                )
                FROM Account
                WHERE Id IN :accounts
        ];
        for (Account acc : accToShare) {
            for (Id userId : usersIdsToShare.get(acc.Territory__c)) {
                accountSharesToSave.add(
                        new AccountShare(
                                AccountId = acc.Id,
                                UserOrGroupId = userId,
                                AccountAccessLevel = 'Read',
                                RowCause = 'Manual',
                                OpportunityAccessLevel = 'Read'
                        ));
                if (acc.References__r.size() != 0) {
                    for (Reference__c linkToContact : acc.References__r) {
                        contactSharesToSave.add(
                                new ContactShare(
                                        ContactId = linkToContact.Contact__c,
                                        UserOrGroupId = userId,
                                        ContactAccessLevel = 'Read',
                                        RowCause = 'Manual'));
                    }
                }
            }
        }
        saveShareObject(accountSharesToSave, 'AccountId');
        saveShareObject(contactSharesToSave, 'ContactId');
    }

    public static void shareContacts(Set<Id> contactsIds) {
        Map<Id, Set<Id>> actualContactsToUsers = getActualUsersForContactSharing(contactsIds);

        List<ContactShare> sharesToCreate = new List<ContactShare>();
        for (Id contId : actualContactsToUsers.keySet()) {
            for (Id userId : actualContactsToUsers.get(contId)) {
                sharesToCreate.add(new ContactShare(
                        ContactId = contId,
                        UserOrGroupId = userId,
                        ContactAccessLevel = 'Read',
                        RowCause = 'Manual'));
            }
        }
        saveShareObject(sharesToCreate, 'ContactId');
    }

    public static void unshareAccounts(List<Account> accounts) {
        List<AccountShare> sharingsForAccounts = [
                SELECT Id, UserOrGroupId
                FROM AccountShare
                WHERE AccountId IN :accounts

                AND RowCause = 'Manual'
        ];
        delete sharingsForAccounts;

        Set<Id> contactsToUnshare = new Set<Id>();
        for (Account acc : [
                SELECT Id, (SELECT Contact__c FROM References__r)
                FROM Account
                WHERE Id IN :accounts
        ]) {
            for (Reference__c reference : acc.References__r) {
                contactsToUnshare.add(reference.Contact__c);
            }
        }
        unshareContacts(contactsToUnshare);
    }


    public static void unshareContacts(Set<Id> contactsIds) {
        Map<Id, Set<Id>> actualContactsToUsers = getActualUsersForContactSharing(contactsIds);
        List<ContactShare> existingSharingForContacts = [
                SELECT ContactId, UserOrGroupId
                FROM ContactShare
                WHERE ContactId IN :contactsIds
                AND RowCause='Manual'
        ];
        List<ContactShare> sharesToRemove = new List<ContactShare>();
        for (ContactShare shar : existingSharingForContacts) {
            if (!actualContactsToUsers.containsKey(shar.ContactId) || !actualContactsToUsers.get(shar.ContactId).contains(shar.UserOrGroupId)) {
                sharesToRemove.add(shar);
            }
        }
        Database.delete(sharesToRemove, false);

    }

    private static Map<Id, Set<Id>> getActualUsersForContactSharing(Set<Id> contactsIds) {
        List<Contact> contactsToUnshare = [
                SELECT Id, (SELECT Account__c FROM References__r)
                FROM Contact
                WHERE Id IN :contactsIds
        ];
        Map<Id, Set<Id>> contactsToAccounts = new Map<Id, Set<Id>>();
        for (Contact cont : contactsToUnshare) {
            Set<Id> accForContact = new Set<Id>();
            for (Reference__c ref : cont.References__r) {
                accForContact.add(ref.Account__c);
            }
            contactsToAccounts.put(cont.Id, accForContact);
        }
        Map<Id, Set<Id>> accountsToContacts = MapConverter.changeMapDirection(contactsToAccounts);

        List<AccountShare> existingSharingForAcc = [
                SELECT AccountId, UserOrGroupId
                FROM AccountShare
                WHERE AccountId IN :accountsToContacts.keySet()
        ];
        Map<Id, Set<Id>> existingAccountsToUsers = new Map<Id, Set<Id>>();
        for (AccountShare shar : existingSharingForAcc) {
            if (existingAccountsToUsers.containsKey(shar.AccountId)) {
                existingAccountsToUsers.get(shar.AccountId).add(shar.UserOrGroupId);
            } else {
                existingAccountsToUsers.put(shar.AccountId, new Set<Id>{
                        shar.UserOrGroupId
                });
            }
        }
        Map<Id, Set<Id>> actualContactsToUsers = new Map<Id, Set<Id>>();
        for (Id contId : contactsToAccounts.keySet()) {
            actualContactsToUsers.put(contId, new Set<Id>());
            for (Id accId : contactsToAccounts.get(contId)) {
                actualContactsToUsers.get(contId).addAll(existingAccountsToUsers.get(accId));
            }
        }
        return actualContactsToUsers;
    }

    private static void saveShareObject(List<SObject> objectsToSave, String idFieldName) {
        if (objectsToSave.size() == 0) {
            return;
        }
        DuplicateCheckService checker = new DuplicateCheckService(objectsToSave, idFieldName, 'UserOrGroupId');
        checker.markDuplicatedObjects();
        Database.insert(objectsToSave, false);
    }


    private static Map<Id, List<Account>> getAccountsOnTerritories(Set<Id> terIds) {
        List<Account> accounts = [
                SELECT Id, Territory__c, (
                        SELECT Contact__c
                        FROM References__r
                )
                FROM Account
                WHERE Territory__c IN :terIds
        ];
        Map<Id, List<Account>> accountsOnTerritories = new Map<Id, List<Account>>();
        for (Account acc : accounts) {
            if (accountsOnTerritories.containsKey(acc.Territory__c)) {
                accountsOnTerritories.get(acc.Territory__c).add(acc);
            } else {
                accountsOnTerritories.put(acc.Territory__c, new List<Account>());
                accountsOnTerritories.get(acc.Territory__c).add(acc);
            }
        }
        return accountsOnTerritories;
    }


}