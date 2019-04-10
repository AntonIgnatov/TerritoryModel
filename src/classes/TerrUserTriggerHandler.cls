/**
 * Created by venzor on 3/30/2019.
 */

public with sharing class TerrUserTriggerHandler {

    public static void beforInsert(List<TerrUser__c> relationsToInsert){
        TerrUserCreationService.checkDuplikatedOrUserEmptyRelations(relationsToInsert);
    }

    public static void beforDelete(List<TerrUser__c> relationsToDelete){
        TerritorySharingService.unshareAccounts(relationsToDelete);
    }

    public static void afterInsert(List<TerrUser__c> insertedRelations){
        TerritorySharingService.shareAccAndConntactsForNewRelation(insertedRelations);
    }
}