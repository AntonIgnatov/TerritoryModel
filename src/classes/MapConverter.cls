/**
 * Created by venzor on 4/6/2019.
 */

public  class MapConverter {

    public static Map<Id, Set<Id>> changeMapDirection(Map<Id, Set<Id>> input){
        Map<Id, Set<Id>> output = new Map<Id, Set<Id>>();
        for(Id key : input.keySet()){
            for(Id val : input.get(key)){
                if(output.containsKey(val)){
                    output.get(val).add(key);
                } else{
                    output.put(val, new Set<Id>{key});
                }
            }
        }
        return output;
    }

}