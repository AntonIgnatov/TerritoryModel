/**
 * Created by venzor on 4/7/2019.
 */

public with sharing class TerritorySharingService {

    public static void shareAccAndConntactsForNewRelation(List<TerrUser__c> newRelations){
        Map<Id, Set<Id>> territoryToUsers = new Map<Id, Set<Id>>();
        for(TerrUser__c relation : newRelations){
            if(territoryToUsers.containsKey(relation.Territory__c)){
                territoryToUsers.get(relation.Territory__c).add(relation.User__c);
            }else {
                territoryToUsers.put(relation.Territory__c, new Set<Id>{relation.User__c});
            }
        }
        Map<Id, Set<Id>> childToParentsTerriroties = TerritoryHierarchyService.getChildsAssociatedToParent(new List<Id>(territoryToUsers.keySet()));
        SharingService.shareAccountsByTerritory(territoryToUsers, childToParentsTerriroties);
        TerritoryHierarchyService.removeOverridedRelations(territoryToUsers, childToParentsTerriroties);
    }

    public static void unshareAccounts(List<TerrUser__c> oldRelations){
        List<TerrUser__c> relationsToUnshare = new List<TerrUser__c>();
        for(TerrUser__c relation : oldRelations){
            if(!relation.SafeDelete__c){
                relationsToUnshare.add(relation);
            }
        }
        Map<Id, Set<Id>> usersToTerritories = new Map<Id, Set<Id>>();
        for(TerrUser__c relation : relationsToUnshare){
            if(usersToTerritories.containsKey(relation.User__c)){
                usersToTerritories.get(relation.User__c).add(relation.Territory__c);
            } else {
                usersToTerritories.put(relation.User__c, new Set<Id>{relation.Territory__c});
            }
        }
        SharingService.unshareAccByTerritory(usersToTerritories);
    }

}