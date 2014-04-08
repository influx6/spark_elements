library spark.elements;

import 'dart:html';
import 'package:sparkflow/sparkflow.dart';
import 'package:hub/hubclient.dart';


class Elements{
    static void registerComponents(){
        Component.registerComponents();
        SparkRegistery.register('elements','MapCss',MapCss.create);
        SparkRegistery.register('elements','RemoveAttr',MapRemoveAttr.create);
        SparkRegistery.register('elements','MapAttributable',MapAttributable.create);
        SparkRegistery.register('elements','GetAttr',GetAttr.create);

        SparkRegistery.register('elements','Attr',Attr.create);

        SparkRegistery.register('elements','element',Element.create);
    }
}

class ElementUtils{

   static Function elementOptionValidator = Funcs.matchConditions([
      (e){ return e is Map; },
      (e){ return e.containsKey('type'); }, 
      (e){ return e.containsKey('query'); }, 
   ]);

}

class MapAttributable extends Component{
  String attr;
  
  static create(fn) => new MapAttributable(fn);
   
  MapAttributable(Function handle): super('MapAttributable'){
    this.removeAllPorts();
    this.makePort('in:attr');
    this.makePort('in:elem');
    this.makePort('out:elem');
    
    this.port('attr').tap((n){
     if(n is! Map) this.attrs = n;
    });
    
    this.port('in:elem').bindPort('out:elem');
     
      this.port('out:elem').dataTransformer.on((elem){
        if(valids.notExist(this.attr)) return null;
        
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
    this.id = "MapRemoveAttr";
  }
}

class MapCss extends MapAttributable{
   
   static create() => new MapCss();
   MapCss(): super((k,v,elem){ elem.style.setProperty(k,v); }){
     this.id = 'MapCss';
   } 
}

class Attr extends Component{
   
   static create() => new Attr();
   Attr(): super('Attr'){
      
     this.makePort('in:get');
     this.makePort('in:set');
     this.makePort('in:elem');
     this.makePort('out:value');
      
     this.port('in:get').forceCondition(Valids.isString);
     this.port('in:set').forceCondition(Valids.isString);
     this.port('out:set').forceCondition(Valids.isString);

     this.port('in:get').tap((n){
     
     });

   }
}


class Util{
  
  static isElement(n) => n.data is Element;
}

class Element extends Component{
  Element elem;
  
  static create() => new Element();

  Element(): super("Element"){
    this.makePort('in:elem');

    this.port('in:elem').forceCondition(Util.isElement);
    this.port('in:elem').tap((n){
      elem = elem;
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

    this.port('in:elem').forceCondition(Util.isElement);
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
        this.meta('id',"QuerySelectorAll");
    }

    void process(n) => this.e.querySelectorAll(n);
}
