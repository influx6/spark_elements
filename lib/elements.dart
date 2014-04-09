library spark.elements;

import 'dart:html';
import 'package:sparkflow/sparkflow.dart';
import 'package:hub/hubclient.dart';

// static class to be called when we need to register this components
//into the global registry
class Elements{
    static void registerComponents(){
        Component.registerComponents();
        SparkRegistry.register('elements','MapCss',MapCSS.create);
        SparkRegistry.register('elements','MapRemoveAttr',MapRemoveAttr.create);
        SparkRegistry.register('elements','MapAttributable',MapAttributable.create);

        SparkRegistry.register('elements','Attr',Attr.create);

        SparkRegistry.register('elements','element',Element.create);
    }

   static isElement(n) => n.data is Element;

   static Function elementOptionValidator = Funcs.matchConditions([
      (e){ return e is Map; },
      (e){ return e.containsKey('type'); }, 
      (e){ return e.containsKey('query'); }, 
   ]);

   static Function attrPacketValidator = Funcs.effect((t){
     return Funcs.matchFunctionalCondition([
       (e){ return e.has('type'); },
       (e){ return Valids.match(e.get('type'),t); }
     ]);
   });
  
}

class Attr extends Component{
   
   static create() => new Attr();
   Attr(): super('Attr'){
      
     this.makePort('in:get');
     this.makePort('in:set');
     this.makePort('in:remove');
     this.makePort('in:elem');
     this.makePort('out:value');

     this.port('in:get').forcePacketCondition(Elements.attrPacketValidator('get'));
     this.port('in:set').forcePacketCondition(Elements.attrPacketValidator('set'));
     this.port('in:remove').forcePacketCondition(Elements.attrPacketValidator('remove'));

     this.port('in:get').forceCondition(Valids.isString);
     /* this.port('in:set').forceCondition(Valids.isString); */
     /* this.port('out:set').forceCondition(Valids.isString); */


     this.port('in:get').tap((n){
     
     });

   }
}

class Element extends Component{
  Element elem;
  
  static create() => new Element();

  Element(): super("Element"){
    this.makePort('in:elem');

    this.port('in:elem').forceCondition(Elements.isElement);
    this.port('in:elem').tap((n){
      this.elem = elem;
    });
  }

}

class QuerySelector extends Component{
  Element e;

  static create() => new QuerySelector();

  QuerySelector(): super("QuerySelector"){
    this.makePort('in:query');
    this.makePort('out:val');
    this.makePort('in:elem');

    this.port('in:elem').forceCondition(Elements.isElement);
    this.port('in:query').forceCondition(Valid.isString);
    this.port('in:query').forceCondition((n){
      if(this.e != null) return true; return false;
    });

    this.port('in:elem').tap((n){ this.e = n.data; });

    this.port('in:query').tap((n){
      this.port('out:val').send(this.process);
    });
    
  }

  void process(n){
    return this.e.querySelector(n.data);
  }
}

class QuerySelectorAll extends QuerySelector{
  
    QuerySelectorAll(): super(){
        this.metas('id',"QuerySelectorAll");
    }

    void process(n) => this.e.querySelectorAll(n);
}

class MapAttributable extends Component{
  String attr;
  
  static create(fn) => new MapAttributable(fn);
   
  MapAttributable(Function handle): super('MapAttributable'){
    this.removeAllPorts();
    this.makePort('in:attr');
    this.makePort('in:elem');
    this.makePort('out:elem');
    
    this.port('in:attr').forceCondition(Valids.isMap);
    this.port('in:attr').tap((n){ this.attrs = n; });
    
    this.port('in:elem').bindPort('out:elem');
     
    this.port('out:elem').forceCondition((n){ return Valids.notExist(this.attr); });
    this.port('out:elem').dataTransformer.on((elem){
        Enums.eachAsyncMap(this.attr,(v,k,o,fn){
           handle(k,v,this.elem);
           fn(false);
        },(o){ this.attr = null; });
        return elem;
    });

  }
  
}

class MapRemoveAttr extends MapAttributable{
  static create() => new MapRemoveAttr();
  MapRemoveAttr(): super((k,v,elem){
  
       Funcs.when(Valids.match(k,'data'),(){
         elem.dataset.remove(v);
       });
       
       Funcs.when(Valids.match(k,'class'),(){
         elem.classes.remove(v);
       });
       
       Funcs.when((Valids.isNot(k,'attr')),(){
         elem.attributes.remove(v);
       });
  
  }){
    this.meta('id','MapRemoveAttr');
  }
}

class MapCSS extends MapAttributable{
   
   static create() => new MapCSS();
   MapCSS(): super((k,v,elem){ elem.style.setProperty(k,v); }){
     this.meta('id','MapCSS');
   } 
}
