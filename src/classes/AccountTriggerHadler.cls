/**
 * Created by venzor on 4/7/2019.
 */

public with sharing class AccountTriggerHadler {

    public static void afterInsert(List<Account> accountsToInsert){
        AccountSharingService.shareNewAccounts(accountsToInsert);
    }

    public static void afterUpdate(Map<Id, Account> accBeforeUpdate, Map<Id, Account> accAfterUpdate) {
        AccountSharingService.separateAccountsToShare(accBeforeUpdate, accAfterUpdate);
    }
}