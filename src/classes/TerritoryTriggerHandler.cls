/**
 * Created by Diz-19 on 27.03.2019.
 */

public class TerritoryTriggerHandler {

    public static void beforeInsert(List<Territory__c> newTerritories){
        TerritoryNameCheckerService.checkNamesExisting(newTerritories);
    }

    public static void beforeUpdate(List<Territory__c> newTerritories){
        TerritoryNameCheckerService.checkNamesExisting(newTerritories);
    }

}