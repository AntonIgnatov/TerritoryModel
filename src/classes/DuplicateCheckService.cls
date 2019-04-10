/**
 * Created by Diz-19 on 02.04.2019.
 */

public with sharing class DuplicateCheckService {

    private List<SObject> newObjects;
    private String fieldOne;
    private String fieldTwo;
    private String objName;

    public DuplicateCheckService(List<SObject> newObjects, String fieldOne, String fieldTwo){
        this.fieldOne = fieldOne;
        this.fieldTwo = fieldTwo;
        this.newObjects = newObjects;
        this.objName = newObjects[0].getSObjectType().getDescribe().getName();
    }


    public  void markDuplicatedObjects() {
        List<Id> fieldOneIds = new List<Id>();
        List<Id> fieldTwoIds = new List<Id>();
        for (SObject obj : this.newObjects) {

            fieldOneIds.add((Id)obj.get(fieldOne));
            fieldTwoIds.add((Id)obj.get(fieldTwo));
        }

        addErrorsToDuplicate();

        Map<Id, Set<Id>> groupedObjects = groupExistingObjects(fieldOneIds, fieldTwoIds);
        for (SObject obj : this.newObjects) {
            if (groupedObjects.containsKey((Id)obj.get(this.fieldOne)) &&
                    groupedObjects.get((Id)obj.get(this.fieldOne)).contains((Id)obj.get(this.fieldTwo))) {
                obj.addError('This relationship already exist');
            }
        }
    }

    private  void addErrorsToDuplicate() {
        Set<SObject> uniqObjects = new Set<SObject>(this.newObjects);
        if (uniqObjects.size() != this.newObjects.size()) {
            for (SObject obj : this.newObjects) {
                if (!uniqObjects.remove(obj)) {
                    obj.addError('This relationship already exist');
                }
            }
        }
    }


    private  Map<Id, Set<Id>> groupExistingObjects(List<Id> fieldOneIds, List<Id> fieldTwoIds) {
        Map<Id, Set<Id>> groupedIdsByOneField = new Map<Id, Set<Id>>();

        String quer = 'SELECT '+ this.fieldOne + ', ' + this.fieldTwo+
                ' FROM ' + this.objName +
                ' WHERE '+this.fieldOne+' IN :fieldOneIds'+
                ' AND '+this.fieldTwo+' IN :fieldTwoIds';

        List<SObject> existingObj = Database.query(quer);

        for (SObject obj : existingObj) {
            if (!groupedIdsByOneField.containsKey((Id)obj.get(this.fieldOne))) {
                groupedIdsByOneField.put(
                        (Id)obj.get(this.fieldOne),
                        new Set<Id>{
                                (Id)obj.get(this.fieldTwo)
                        });
            } else {
                groupedIdsByOneField.get((Id)obj.get(this.fieldOne)).add((Id)obj.get(this.fieldTwo));
            }
        }
        return groupedIdsByOneField;
    }
}