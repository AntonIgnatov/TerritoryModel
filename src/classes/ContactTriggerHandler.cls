/**
 * Created by venzor on 3/28/2019.
 */

public with sharing class ContactTriggerHandler {

    public static void beforeInsert(List<Contact> newContacts){
        ContactCreationService.setFakeAccToContact(newContacts);
    }

}