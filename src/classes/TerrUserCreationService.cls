/**
 * Created by venzor on 3/30/2019.
 */

public with sharing class TerrUserCreationService {

    public static void checkDuplikatedOrUserEmptyRelations(List<TerrUser__c> relations) {
        for (TerrUser__c relation : relations) {
            if (relation.User__c == null) {
                relation.addError('User must be specified');
                continue;
            }
        }
        DuplicateCheckService checker = new DuplicateCheckService(relations, 'User__c', 'Territory__c');
        checker.markDuplicatedObjects();
        TerritoryHierarchyService.markAssigningToParentTerritory(relations);
    }



}