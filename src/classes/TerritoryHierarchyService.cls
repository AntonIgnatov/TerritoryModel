/**
 * Created by Diz-19 on 29.03.2019.
 */

public class TerritoryHierarchyService {

    public static Map<Id, Set<Id>> getChildsAssociatedToParent(List<Id> territoriesIds) {
        Map<Id, Set<Id>> parentToChilds = getTerritoriesIdsForDescendingHierarchy(territoriesIds);
        Map<Id, Set<Id>> childsToParent = MapConverter.changeMapDirection(parentToChilds);
        return childsToParent;
    }

    public static void markAssigningToParentTerritory(List<TerrUser__c> relations) {
        Set<Id> usedTerritoriesIds = new Set<Id>();
        Map<Id, Set<Id>> userToTerritiries = new Map<Id, Set<Id>>();
        for (TerrUser__c relation : relations) {
            usedTerritoriesIds.add(relation.Territory__c);
            if (userToTerritiries.containsKey(relation.User__c)) {
                userToTerritiries.get(relation.User__c).add(relation.Territory__c);
            } else {
                userToTerritiries.put(relation.User__c, new Set<Id>{
                        relation.Territory__c
                });
            }
        }
        Map<Id, Set<Id>> risingHierarchyForRelations = getRisingHierarchy(usedTerritoriesIds);
        Set<Id> allTerrInRisingBulkOperation = new Set<Id>();
        for (Id childTerr : risingHierarchyForRelations.keySet()) {
            allTerrInRisingBulkOperation.addAll(risingHierarchyForRelations.get(childTerr));
        }
        List<TerrUser__c> sameUsersOnHiherHierarchyForCompare = [
                SELECT User__c, Territory__c
                FROM TerrUser__c
                WHERE Territory__c IN :allTerrInRisingBulkOperation
                AND User__c IN :userToTerritiries.keySet()
        ];
        Map<Id, Set<Id>> existingRelationsToTerr = new Map<Id, Set<Id>>();
        for (TerrUser__c existRelation : sameUsersOnHiherHierarchyForCompare) {
            if (existingRelationsToTerr.containsKey(existRelation.Territory__c)) {
                existingRelationsToTerr.get(existRelation.Territory__c).add(existRelation.User__c);
            } else {
                existingRelationsToTerr.put(existRelation.Territory__c, new Set<Id>{
                        existRelation.User__c
                });
            }
        }

        for (TerrUser__c relation : relations) {
            for (Id terrHighLvl : risingHierarchyForRelations.get(relation.Territory__c)) {
                if (existingRelationsToTerr.containsKey(terrHighLvl) &&
                        existingRelationsToTerr.get(terrHighLvl).contains(relation.User__c)) {
                    relation.addError('User already asigned to parent Territory');
                }
            }
        }


    }

    public static void removeOverridedRelations(Map<Id, Set<Id>> relationsOnOperation, Map<Id, Set<Id>> descHierarchies) {
        List<TerrUser__c> owerridedRelations = getOwerrideRelationOnDescendingHierarchy(relationsOnOperation, descHierarchies);
        for (TerrUser__c relation : owerridedRelations) {
            relation.SafeDelete__c = true;
        }
        upsert owerridedRelations;
        delete owerridedRelations;
    }

    public static Map<Id, Set<Id>> getUsersIdsOnRisingHierarchy(Set<Id> startTerrIds) {
        Map<Id, Set<Id>> risingHierarhy = getRisingHierarchy(startTerrIds);
        for(Id startTer : risingHierarhy.keySet()){
            risingHierarhy.get(startTer).add(startTer);
        }
        Set<Id> allTerrOnRisHierarchy = new Set<Id>();
        for (Set<Id> territories : risingHierarhy.values()) {
            allTerrOnRisHierarchy.addAll(territories);
        }
        List<TerrUser__c> relationsOnRisingHierarchy = [
                SELECT Territory__c, User__c
                FROM TerrUser__c
                WHERE Territory__c IN :allTerrOnRisHierarchy
        ];
        Map<Id, Set<Id>> terrToUser = new Map<Id, Set<Id>>();
        for (TerrUser__c relation : relationsOnRisingHierarchy) {
            if (terrToUser.containsKey(relation.Territory__c)) {
                terrToUser.get(relation.Territory__c).add(relation.User__c);
            } else {
                terrToUser.put(relation.Territory__c, new Set<Id>{
                        relation.User__c
                });
            }
        }
        Map<Id, Set<Id>> usersOnRisingHierarchy = new Map<Id, Set<Id>>();
        for (Id startTer : startTerrIds) {
            Set<Id> usersForSingleHierarchy = new Set<Id>();
            for (Id parentTer : risingHierarhy.get(startTer)) {
                if (terrToUser.containsKey(parentTer)) {
                    usersForSingleHierarchy.addAll(terrToUser.get(parentTer));
                }
            }
            usersOnRisingHierarchy.put(startTer, usersForSingleHierarchy);
        }
        return usersOnRisingHierarchy;
    }

    private static List<TerrUser__c> getOwerrideRelationOnDescendingHierarchy(Map<Id, Set<Id>> relationsOnOperation, Map<Id, Set<Id>> descHierarchies) {

        for (Id currentTer : relationsOnOperation.keySet()) {
            descHierarchies.remove(currentTer);
        }
        Set<Id> usersIds = new Set<Id>();
        for (Set<Id> users : relationsOnOperation.values()) {
            usersIds.addAll(users);
        }
        List<TerrUser__c> existingRelationsOnHierarchy = [
                SELECT User__c, Territory__c
                FROM TerrUser__c
                WHERE User__c IN :usersIds
                AND Territory__c IN :descHierarchies.keySet()
        ];
        List<TerrUser__c> overridedRelations = new List<TerrUser__c>();

        for (TerrUser__c relation : existingRelationsOnHierarchy) {
            if (descHierarchies.containsKey(relation.Territory__c)) {
                for (Id terrId : descHierarchies.get(relation.Territory__c)) {
                    if (relationsOnOperation.containsKey(terrId) && relationsOnOperation.get(terrId).contains(relation.User__c)) {
                        overridedRelations.add(relation);
                    }
                }
            }
        }

        return overridedRelations;
    }

    private static Map<Id, Set<Id>> getRisingHierarchy(Set<Id> terrIdsToFindParents) {
        Map<Id, Id> childToParent = new Map<Id, Id>();
        Set<Id> childs = new Set<Id>(terrIdsToFindParents);
        while (childs.size() != 0) {
            List<Territory__c> tempTerritories = [
                    SELECT Id, TerritoryParent__c, TerritoryParent__r.TerritoryParent__c, TerritoryParent__r.TerritoryParent__r.TerritoryParent__c
                    FROM Territory__c
                    WHERE Id IN :childs
            ];
            childs.clear();
            for (Territory__c ter : tempTerritories) {
                childToParent.put(ter.Id, ter.TerritoryParent__c);
                if (ter.TerritoryParent__c != null) {
                    childToParent.put(ter.TerritoryParent__c, ter.TerritoryParent__r.TerritoryParent__c);
                    if (ter.TerritoryParent__r.TerritoryParent__c != null) {
                        childToParent.put(ter.TerritoryParent__r.TerritoryParent__c, ter.TerritoryParent__r.TerritoryParent__r.TerritoryParent__c);
                        childs.add(ter.TerritoryParent__r.TerritoryParent__r.TerritoryParent__c);
                        continue;
                    }
                    childs.add(ter.TerritoryParent__r.TerritoryParent__c);
                    continue;
                }
                childs.add(ter.TerritoryParent__c);
            }
            childs.remove(null);
        }
        Map<Id, Set<Id>> allParentsToChIds = new Map<Id, Set<Id>>();
        for (Id terId : terrIdsToFindParents) {
            allParentsToChIds.put(terId, new Set<Id>());
            Id tempTerId = terId;
            while (childToParent.containsKey(tempTerId)) {
                allParentsToChIds.get(terId).add(childToParent.get(tempTerId));
                tempTerId = childToParent.get(tempTerId);
            }
        }
        return allParentsToChIds;
    }

    private static Map<Id, Set<Id>> getTerritoriesIdsForDescendingHierarchy(List<Id> parentsIds) {
        Map<Id, Set<Id>> allChildsForUsersTerritory = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> parentsToAllChilds = new Map<Id, Set<Id>>();

        for (Integer i = 0; i < parentsIds.size(); i++) {
            if (allChildsForUsersTerritory.containsKey(parentsIds[i])) {

                Set<Id> allTerritoriesIds = new Set<Id>{
                        parentsIds[i]
                };
                Set<Id> childsIds = allChildsForUsersTerritory.get(parentsIds[i]);
                allTerritoriesIds.addAll(childsIds);

                while (childsIds.size() != 0) {

                    Set<Id> tempChildsIds = new Set<Id>(childsIds);
                    childsIds.clear();

                    for (Id childId : tempChildsIds) {

                        childsIds.addAll(allChildsForUsersTerritory.get(childId));
                    }
                    allTerritoriesIds.addAll(childsIds);
                }
                parentsToAllChilds.put(parentsIds[i], allTerritoriesIds);
            } else {
                allChildsForUsersTerritory.putAll(getParentsAssociatedToChilds(parentsIds[i], allChildsForUsersTerritory));
                i--;
            }
        }

        return parentsToAllChilds;
    }

    private static Map<Id, Set<Id>> getParentsAssociatedToChilds(Id parentIdToSearch, Map<Id, Set<Id>> allChilds) {
        Map<Id, Set<Id>> parentToChildsAssociateons = new Map<Id, Set<Id>>();
        parentToChildsAssociateons.put(parentIdToSearch, new Set<Id>());

        List<Id> parentsId = new List<Id>();
        parentsId.add(parentIdToSearch);
        while (parentsId.size() != 0) {

            List<Territory__c> tempTerritories = [
                    SELECT Id, (
                            SELECT Id
                            FROM Child_Territories__r
                    )
                    FROM Territory__c
                    WHERE Id IN :parentsId
            ];

            parentsId.clear();

            for (Territory__c parent : tempTerritories) {
                Set<Id> childsIds = new Set<Id>();
                for (Territory__c child : parent.Child_Territories__r) {
                    childsIds.add(child.Id);
                    parentToChildsAssociateons.put(child.Id, new Set<Id>());
                }

                childsIds.removeAll(allChilds.keySet());
                parentToChildsAssociateons.put(parent.Id, childsIds);
                parentsId.addAll(childsIds);

            }
        }
        return parentToChildsAssociateons;
    }


}