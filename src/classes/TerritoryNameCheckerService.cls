/**
 * Created by venzor on 27.03.2019.
 */

public class TerritoryNameCheckerService {

    public static void checkNamesExisting(List<Territory__c> territoriesToCheck) {
        Set<String> namesOfNewTerritories = new Set<String>();
        Set<Id> parentsIds = new Set<Id>();


        for (Territory__c ter : territoriesToCheck) {
            namesOfNewTerritories.add(ter.Name);
            parentsIds.add(ter.TerritoryParent__c);
        }

        List<Territory__c> existingTerritory = getExistingTerritoryByName(parentsIds, namesOfNewTerritories);

        if (existingTerritory.size() == 0) {
            return;
        }

        Map<Id, Set<String>> namesOnParent = getUsedNamesOnTerritores(existingTerritory);

        for (Territory__c ter : territoriesToCheck) {
            if (namesOnParent.containsKey(ter.TerritoryParent__c) &&
                    namesOnParent.get(ter.TerritoryParent__c).contains(ter.Name)) {
                ter.addError('Territory ' + ter.Name + ' already exist');
            }
        }

    }

    private static Map<Id, Set<String>> getUsedNamesOnTerritores(List<Territory__c> territories) {
        Map<Id, Set<String>> namesOnParentTerritory = new Map<Id, Set<String>>();

        for (Territory__c ter : territories) {
            Set<String> childNames = new Set<String>{ter.Name};
            for(Territory__c childTer : ter.Child_Territories__r){
                childNames.add(childTer.Name);
            }
            namesOnParentTerritory.put(ter.Id, childNames);
        }

        return namesOnParentTerritory;
    }


    private static List<Territory__c> getExistingTerritoryByName(Set<Id> parents, Set<String> names) {
        return [
                SELECT ID, Name, (SELECT Id, Name FROM Child_Territories__r WHERE Name IN :names)
                FROM Territory__c
                WHERE Id IN :parents
        ];
    }


}