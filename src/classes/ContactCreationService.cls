/**
 * Created by venzor on 3/28/2019.
 */

public class ContactCreationService {

    private static final Id FAKE_ACCOUNT_ID;

    static {

        List<Account> fakeAcc = [
                SELECT Id
                FROM Account
                WHERE Name = 'Fake'
                ORDER BY CreatedDate
                LIMIT 1
        ];
        FAKE_ACCOUNT_ID = fakeAcc[0].Id;
    }

    public static void setFakeAccToContact(List<Contact> contacts) {

        for (Contact contact : contacts) {
            contact.AccountId = FAKE_ACCOUNT_ID;
        }
    }
}