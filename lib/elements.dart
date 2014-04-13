library spark.elements;

import 'dart:html' as html;
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
        SparkRegistry.register('elements','AttrCore',AttrCore.create);
        SparkRegistry.register('elements','GetAttr',GetAttr.create);
        SparkRegistry.register('elements','SetAttr',SetAttr.create);

        SparkRegistry.register('elements','Element',Element.create);
    }

   static isElement(n) => n is html.Element;

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
  
   static elementExist => Funcs.alwaysEffect(Valids.exist);
}

class AttrCore extends Component{
    html.Element elem;

    static create() => new AttrCore();

    AttrCore(): super('AttrCore'){
      this.removeDefaultPorts();
    
      this.makePort('in:elem');
      this.port('in:elem').forceCondition(Elements.isElement);
      this.port('in:elem').tap((e){ this.elem = e.data; });
    }
}

class GetAttr extends AttrCore{

    static create() => new GetAttr();

    GetAttr(){
      this.meta('id','GetAttr');
      this.makePort('in:get');
      this.makePort('out:value');
      
      this.port('in:get').forceCondition(Elements.elementExist(this.elem));
      this.port('in:get').forceCondition(Valids.isString);

      this.port('in:get').tap((n){
        this.port('out:value').send(this.elem.getAttribute(n.data));
      });

    }
}

class SetAttr extends AttrCore{
    
    static create() => new SetAttr();

    SetAttr(){
      String key;
      dynamic val;

      this.meta('id','SetAttr');

      this.makePort('in:key');
      this.makePort('in:val');

      this.port('in:val').forceCondition(Elements.elementExist(this.elem));
      this.port('in:val').forceCondition(Funcs.alwaysEffect(Valids.exist)(key));
      this.port('in:key').forceCondition(Valids.isString);

      this.port('in:key').tap((n){
          key = n.data;
      });

      this.port('in:val').tap((n){
        this.elem.setAttribute(key,this.processData(n));
      });

    }

    dynamic processData(n){
      if(Valids.isList(n.data)) return n.join(';');
      if(Valids.isString(n.data)) return n.data;
    }

}

class Attr extends Component{
   
   static create() => new Attr();

   Attr(): super('Attr'){
     this.removeDefaultPorts();
     this.enableSubnet();
     this.network.removeDefaultPorts();
     
     this.makePort('in:elem');
     this.makePort('in:get');
     this.makePort('in:set');
     this.makePort('in:val');
     this.makePort('out:value');
      

     this.network.makePort('in:elem');
     this.network.makePort('in:get');
     this.network.makePort('in:set');
     this.network.makePort('in:val');
     this.network.makePort('out:value');

     this.port('in:elem').bindPort(this.network.port('in:elem'));
     this.port('in:get').bindPort(this.network.port('in:get'));
     this.port('in:set').bindPort(this.network.port('in:set'));
     this.port('in:val').bindPort(this.network.port('in:val'));
     this.port('out:value').bindPort(this.network.port('out:value'));

     this.network.port('in:elem').forceCondition(Elements.isElement);
     this.network.port('static:option').bindPort(this.port('in:elem'));
      
     this.network.add('elements/GetAttr','getAttr');
     this.network.add('elements/SetAttr','setAttr');
    
     this.network.ensureBinding('getAttr','in:elem','*','in:elem');
     this.network.ensureBinding('setAttr','in:elem','*','in:elem');

     this.network.ensureBinding('getAttr','out:value','*','out:out');
     this.network.ensureBinding('getAttr','in:get','*','in:get');
     this.network.ensureBinding('getAttr','in:value','*','in:value');

     this.network.ensureBinding('setAttr','in:val','*','in:val');
     this.network.ensureBinding('setAttr','in:set','*','in:set');

   }
}

class AddClass extends AttrCore{
  
    AddClass(){
      this.meta('id','AddClass');

      this.makePort('in:class');
      
      this.port('in:val').forceCondition(Elements.elementExist(this.elem));
      this.port('in:val').forceCondition(Valids.isString);
      this.port('in:val').tap((n){
        this.elem.classes.add(n.data);
      });
    }
}

class RemoveClass extends AttrCore{

    RemoveClass(){
      this.meta('id','RemoveClass');

      this.makePort('in:val');
      this.makePort('out:success');
      this.makePort('err:failed');

      this.port('in:val').forceCondition(Elements.elementExist(this.elem));
      this.port('in:val').forceCondition(Valids.isString);
      this.port('in:val').tap((n){
          if(!this.elem.classes.contains(n.data)) return this.port('err:failed').send(n);
          this.elem.remove(n.data);
          this.port('out:success').send(n);
      });
    }

}

class HasClass extends AttrCore{

    HasClass(){
      this.meta('id','HasClass');

      this.makePort('in:val');
      this.makePort('out:true');
      this.makePort('err:false');

      this.port('in:val').forceCondition(Elements.elementExist(this.elem));
      this.port('in:val').forceCondition(Valids.isString);
      this.port('in:val').tap((n){
          if(!this.elem.classes.contains(n.data)) return this.port('err:false').send(n);
          this.port('out:true').send(n);
      });
    }

}

class GetDataAttr extends AttrCore{

    GetDataAttr(){
      this.meta('id','GetDataAttr');

      this.makePort('in:get');
      this.makePort('out:val');

      this.port('in:get').forceCondition(Elements.elementExist(this.elem));
      this.port('in:get').forceCondition(Valids.isString);

      this.port('in:get').tap((n){
         Funcs.when(this.elem.dataset.containsKey(n.data),(){
           this.port('out:val').send(this.elem.dataset[n.data]);
         });
      });

    }
}

class SetDataAttr extends AttrCore{
    var key;

    SetDataAttr(){
      this.meta('id','SetDataAttr');

      this.makePort('in:key');
      this.makePort('in:val');

      this.port('in:val').forceCondition(Elements.elementExist(this.elem));
      this.port('in:key').forceCondition(Valids.isString);

      this.port('in:key').tap((n){
        this.key = key;
      });

      this.port('in:val').tap((n){
        this.elem.setAttribute(this.key,n.data);
      });

    }
}

class DataAttr extends Component{

    DataAttr(){
      this.meta('id','DataAttr');
      this.enableSubnet();

      this.makePort('in:get');
      this.makePort('in:elem');
      this.makePort('in:set');
      this.makePort('in:val');
      this.makePort('out:val');

      this.network.makePort('in:get');
      this.network.makePort('in:elem');
      this.network.makePort('in:set');
      this.network.makePort('in:val');
      this.network.makePort('out:val');
      
      this.port('in:elem').bindPort(this.network.port('in:elem'));
      this.port('in:get').bindPort(this.network.port('in:get'));
      this.port('in:set').bindPort(this.network.port('in:set'));
      this.port('in:val').bindPort(this.network.port('in:val'));
      this.port('out:val').bindPort(this.network.port('out:val'));

      this.network.port('in:elem').forceCondition(Elements.isElement);
      this.network.port('static:option').bindPort(this.port('in:elem'));
    
      this.network.port('in:get').forceCondition(Valids.isString);
      this.network.port('in:val').forceCondition(Valids.isString);
      this.network.port('in:set').forceCondition(Valids.isString);

      this.network.add('elements/GetDataAttr','getDataAttr');
      this.network.add('elements/SetDataAttr','setDataAttr');
  
      this.network.ensureBinding('getDataAttr','in:elem','*','in:elem');
      this.network.ensureBinding('setDataAttr','in:elem','*','in:elem');

      this.network.ensureBinding('getDataAttr','in:elem','*','in:elem');
      this.network.ensureBinding('getDataAttr','in:get','*','in:get');
      this.network.ensureBinding('getDataAttr','out:val','*','out:val');

      this.network.ensureBinding('setDataAttr','in:elem','*','in:elem');
      this.network.ensureBinding('setDataAttr','in:set','*','in:set');
      this.network.ensureBinding('setDataAttr','in:val','*','in:val');

    }
}

class WriteHTML extends AttrCore{
  
    WriteHTML(){
      this makePort('in:html');
      this makePort('out:elem');

      this.port('in:html').forceCondition(Valids.isString);
      this.port('in:html').tap((n){
        this.elem.innerHTML = n.data;
        this.port('out:elem').send(this.elem);
      });
    }
}

class ReadHTML extends AttrCore{
  
    ReadHTML(){
      this.makePort('out:html');

      this.port('in:elem').tap((n){
        this.port('out:html').send(n.data.innerHTML);
      });
    }
}

class Element extends Component{
  html.Element elem;
  
  static create() => new Element();

  Element(): super("Element"){
    this.makePort('in:elem');
    this.makePort('out:elem');
    

    this.port('in:elem').forceCondition(Elements.isElement);

    this.port('in:elem').onSocketSubscription((sub){
        this.port('in:elem').send(this.elem,sub.get('alias'));
    });

    this.port('in:elem').tap((n){
      this.elem = n.data;
      this.port('out:elem').send(n);
    });


  }

}

class QuerySelector extends Component{
  html.Element e;

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
      this.port('out:val').send(this.process(n));
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

    void process(n) => this.e.querySelectorAll(n.data);
}

class MapAttributable extends Component{
  String attr;
  
  static create(fn) => new MapAttributable(fn);
   
  MapAttributable(Function handle): super('MapAttributable'){
    this.removeDefaultPorts();
    this.makePort('in:attr');
    this.makePort('in:elem');
    this.makePort('out:elem');
    
    this.port('in:attr').forceCondition(Valids.isMap);
    this.port('in:attr').tap((n){ this.attr = n; });
    
    this.port('in:elem').bindPort('out:elem');
     
    this.port('out:elem').forceCondition((n){ return Valids.exist(this.attr); });
    this.port('out:elem').dataTransformer.on((elem){
        Enums.eachAsyncMap(this.attr,(v,k,o,fn){
           handle(k,v,elem);
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
         elem.data.dataset.remove(v);
       });
       
       Funcs.when(Valids.match(k,'class'),(){
         elem.data.classes.remove(v);
       });
       
       Funcs.when((Valids.isNot(k,'attr')),(){
         elem.data.attributes.remove(v);
       });
  
  }){
    this.meta('id','MapRemoveAttr');
  }
}

class MapCSS extends MapAttributable{
   
   static create() => new MapCSS();
   MapCSS(): super((k,v,elem){ elem.data.style.setProperty(k,v); }){
     this.meta('id','MapCSS');
   } 
}
