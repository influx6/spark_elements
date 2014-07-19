library spark.elements;

import 'dart:html' as html;
import 'package:sparkflow/sparkflow.dart';
import 'package:hub/hubclient.dart';

// static class to be called when we need to register this components
//into the global registry
class Elements{


    static void registerComponents(){

        SparkFlow.createRegistry('html',(r){

          r.register('dom','MapCss',MapCSS.create);
          r.register('dom','MapRemoveAttr',MapRemoveAttr.create);
          r.register('dom','MapAttributable',MapAttributable.create);

          r.register('dom','Attr',Attr.create);
          r.register('dom','AttrCore',AttrCore.create);
          r.register('dom','GetAttr',GetAttr.create);
          r.register('dom','SetAttr',SetAttr.create);
          r.register('dom','ReadHTML',ReadHTML.create);
          r.register('dom','WriteHTML',WriteHTML.create);
          r.register('dom','GetDataAttr',GetDataAttr.create);
          r.register('dom','SetDataAttr',SetDataAttr.create);
          r.register('dom','AddClass',AddClass.create);
          r.register('dom','HasClass',HasClass.create);
          r.register('dom','RemoveClass',RemoveClass.create);
          r.register('dom','CSS',CSS.create);

          r.register('dom','QuerySelectorAll',QuerySelectorAll.create);
          r.register('dom','QuerySelector',QuerySelector.create);

          r.addMutation('dom/eventfilter',(m){
                m.meta('desc','allows filtering of dom events by typeName or with a list of allowed typeNames and allows invertion to block only those listed');

                  var allowed = "all";
                  bool reverse = false;

                  m.createSpace('ev');
                  m.createSpace('state');
                  m.createSpace('type');

                  m.makeInport('type:allowed',
                      meta:{'description':'takes a string or list of allowed event names' });
                  m.makeInport('ev:events',
                      meta:{'description':"the port where all events comes in"});
                  m.makeInport('state:invert',
                      meta:{'description':"takes a bool operation that inverts the operation"});

                  m.makeOutport('state:pass');
                  m.makeOutport('state:fail');
                  
                  m.port('state:invert').forceCondition(Valids.isBool);
                  m.port('ev:events').forceCondition(Elements.isEvent);

                  m.port('state:invert').tap((n){
                    reverse = n.data;
                  });

                  m.port('type:allowed').forceCondition((n){
                    return (Valids.isString(n) || Valids.isList(n) ? true : false);
                  });

                  m.port('type:allowed').tap((n){
                    allowed = n.data;
                  });
                

                var _handle = (fn,fe,n){
                    var type = n.has('eventType') ? n.get('eventType') : n.data.type;

                    if(Valids.isString(allowed)){
                    
                      Funcs.when(Valids.match(allowed,"all"),(){
                         return fn(n);
                      });

                      Funcs.when(Valids.match(allowed,"none"),(){
                         return fe(n);
                      });

                      Funcs.when(Valids.match(type,allowed),(){
                         return fn(n);
                      },(){
                        return fe(n);
                      });
                
                      return null;
                    }


                    if(Valids.isList(m.allowed))
                      return Funcs.when(allowed.contains(type),(){
                        return fn(n);
                      },(){
                        return fe(n);
                      });

                    return fe;
                };

                var sendFailure = (n){
                  var fail = m.port('state:fail');
                  if(fail.hasSubscribers) return fail.send(n);
                  return null;
                };

                var filter = (m){

                  Funcs.when(reverse,(){

                     return _handle((n){
                        return sendFailure(n);
                     },(n){
                        return m.port('state:pass').send(n);
                     },m);

                  },(){
                      
                     return _handle((n){
                        return m.port('state:pass').send(n);
                     },(n){
                        return sendFailure(n);
                     },m);

                  });


                };

                m.port('ev:events').tap(filter);

            });

            r.addMutation('dom/eventreactor',(m){
                m.meta('desc','provides a dom element event pipe through which events pass through');

                Function runner;

                m.enableSubnet();
                m.createSpace('evin');

                m.makeInport('evin:events',meta:{'desc':"stream of events"});
                m.makeInport('evin:fn',meta:{"desc":"a function to apply all events with "});
                
                m.port('static:option').bindPort(m.port('evin:fn'));
            
                m.port('evin:events').forceCondition(Elements.isEvent);
                m.port('evin:fn').forceCondition(Valids.isFunction);

                m.port('evin:events').pause();

                m.port('evin:fn').tap((n){
                   runner = n.data;
                   m.port('evin:events').resume();
                });
            });

          r.addMutation('dom/Element',(m){

              var eventcards = MapDecorator.create();
              m.meta('desc','provides a self contained dom element');

              m.sd.add('elem',null);

              m.createSpace('in');
              m.createSpace('out');
              m.createSpace('events');

              m.makeInport('in:elem');
              m.makeOutport('out:elem');
              m.makeInport('events:sub');
              m.makeInport('events:unsub');
              m.makeOutport('events:events');

              m.port('in:elem').forceCondition(Elements.isElement);

              m.port('out:elem').pause();

              m.port('in:elem').tap((n){
                m.sharedData.update('elem',n.data);
                m.port('out:elem').send(n);
                m.port('out:elem').resume();
              });

              var notifyEvent = (packet){
                if(eventcards.has(packet.data)) return null;
                var fn = (e){
                  var pack = m.port('events:events').createDataPacket(e);
                  pack.update('eventType',packet.data);
                  return m.port('events:events').send(pack);
                };

                eventcards.add(packet.data,fn);
                m.sd.get('elem').addEventListener(packet.data,fn);
              };

              var unNotifyEvent = (packet){
                if(!m.eventcards.has(packet.data)) return null;
                var fn = eventcards.destroy(packet.data);
                m.sd.get('elem').addEventListener(packet.data,fn);
              };


              m.port('events:sub').pause();
              m.port('events:unsub').pause();
            
              m.port('events:sub').forceCondition(Valids.isString);
              m.port('events:unsub').forceCondition(Valids.isString);

              m.port('events:sub').tap(notifyEvent);
              m.port('events:unsub').tap(unNotifyEvent);

              m.port('events:sub').tap(notifyEvent);
              m.port('events:unsub').tap(unNotifyEvent);

              m.port('in:elem').tap((pack){
                m.port('events:sub').resume();
                m.port('events:unsub').resume();
              });

          });

      });

   }

   static bool isEvent(e) => e is html.Event;
        
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
  
}

class AttrCore extends Component{
    html.Element elem;

    static create() => new AttrCore();

    AttrCore(): super('AttrCore'){
      
      this.createSpace('in');
      this.createSpace('out');

      this.makeInport('in:elem');

      this.port('static:option').bindPort(this.port('in:elem'));

      this.port('in:elem').forceCondition(Elements.isElement);
      this.port('in:elem').tap((e){ this.elem = e.data; });
    }
}

class CSS extends AttrCore{
  var prop;

  static create() => new CSS();

  CSS(){
    this.meta('id','CSS');

    this.makeInport('in:get');
    this.makeOutport('out:val');

    this.makeInport('in:key');
    this.makeInport('in:val');

    this.port('in:get').pause();
    this.port('in:val').pause();
    this.port('in:key').pause();

    this.port('in:elem').tap((n){
      this.port('in:get').resume();
      this.port('in:val').resume();
      this.port('in:key').resume();
    });

    
    this.port('in:get').forceCondition(Valids.isString);
    this.port('in:key').forceCondition(Valids.isString);

    this.port('in:get').tap((n){
      this.port('out:val').send(this.elem.style.getPropertyValue(n.data));
    });

    this.port('in:key').tap((n){
      this.prop = n.data;
    });

    this.port('in:val').tap((n){
      this.elem.style.setProperty(this.prop,n.data);
    });

  }
}

class GetAttr extends AttrCore{

    static create() => new GetAttr();

    GetAttr(){
      this.meta('id','GetAttr');
      this.makeInport('in:get');
      this.makeOutport('out:value');
      
      this.port('in:get').pause();
      this.port('in:get').forceCondition(Valids.isString);

      this.port('in:elem').tap((n){
        this.port('in:get').resume();
      });

      this.port('in:get').tap((n){
        this.port('out:value').send(this.elem.getAttribute(n.data));
      });

    }
}

class SetAttr extends AttrCore{
    
    static create() => new SetAttr();

    SetAttr(){
      String key;

      this.meta('id','SetAttr');

      this.makeInport('in:key');
      this.makeInport('in:val');
      this.makeOutport('out:done');
  
      this.port('in:val').pause();

      var resumekey = (){
        return Funcs.when(Valids.exist(this.elem) && Valids.exist(key),(){
            this.port('in:val').resume();
        });
      };

      this.port('in:key').forceCondition(Valids.isString);

      this.port('in:elem').tap((n){
          resumekey();
      });

      this.port('in:key').tap((n){
          key = n.data;
          resumekey();
      });

      this.port('in:val').tap((n){
        this.elem.setAttribute(key,this.processData(n));
        this.port('out:done').send(true);
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
     
     this.enableSubnet();
     this.createSpace('in');
     this.createSpace('out');

     this.makeInport('in:elem');
     this.makeInport('in:get');
     this.makeInport('in:set');
     this.makeInport('in:val');
     this.makeOutport('out:value');
      

     this.network.createSpace('in');
     this.network.createSpace('out');
     this.network.makeInport('in:elem');
     this.network.makeInport('in:get');
     this.network.makeInport('in:set');
     this.network.makeInport('in:val');
     this.network.makeOutport('out:value');
    
     this.port('static:option').bindPort(this.port('in:elem'));

     this.port('in:elem').bindPort(this.network.port('in:elem'));
     this.port('in:get').bindPort(this.network.port('in:get'));
     this.port('in:set').bindPort(this.network.port('in:set'));
     this.port('in:val').bindPort(this.network.port('in:val'));
     this.network.port('out:value').bindPort(this.port('out:value'));

     this.network.add('html/dom/GetAttr','getAttr');
     this.network.add('html/dom/SetAttr','setAttr');
    
     this.network.ensureBinding('getAttr','in:elem','*','in:elem');
     this.network.ensureBinding('setAttr','in:elem','*','in:elem');

     this.network.ensureBinding('getAttr','in:get','*','in:get');
     this.network.ensureBinding('getAttr','in:value','*','in:value');

     this.network.ensureBinding('setAttr','in:val','*','in:val');
     this.network.ensureBinding('setAttr','in:key','*','in:set');

     this.network.ensureBinding('*','out:value','getAttr','out:value');
   }
}

class AddClass extends AttrCore{
      
    static create() => new AddClass();

    AddClass(){
      this.meta('id','AddClass');

      this.makeInport('in:class');
      this.makeInport('in:val');
      
      this.port('in:val').pause();

      this.port('in:elem').tap((n){
        this.port('in:val').resume();
      });

      this.port('in:val').forceCondition(Valids.isString);

      this.port('in:val').tap((n){
        this.elem.classes.add(n.data);
      });

    }
}

class RemoveClass extends AttrCore{

    static create() => new RemoveClass();

    RemoveClass(){
      this.createSpace('err');
      this.meta('id','RemoveClass');

      this.makeInport('in:val');
      this.makeOutport('out:success');
      this.makeOutport('err:failed');

      this.port('in:val').pause();

      this.port('in:elem').tap((n){
        this.port('in:val').resume();
      });

      this.port('in:val').forceCondition(Valids.isString);
      this.port('in:val').tap((n){
          if(!this.elem.classes.contains(n.data)) 
              return this.port('err:failed').send(n);
          this.elem.remove(n.data);
          this.port('out:success').send(n);
      });
    }

}

class HasClass extends AttrCore{

    static create() => new HasClass();

    HasClass(){
      this.createSpace('err');
      this.meta('id','HasClass');

      this.makeInport('in:val');
      this.makeOutport('out:true');
      this.makeInport('err:false');

      this.port('in:val').pause();

      this.port('in:elem').tap((n){
        this.port('in:val').resume();
      });

      this.port('in:val').forceCondition(Valids.isString);
      this.port('in:val').tap((n){
          if(!this.elem.classes.contains(n.data)) 
              return this.port('err:false').send(n);
          this.port('out:true').send(n);
      });
    }

}

class GetDataAttr extends AttrCore{

    static create() => new GetDataAttr();
    GetDataAttr(){
      this.meta('id','GetDataAttr');

      this.makeInport('in:get');
      this.makeOutport('out:val');

      this.port('in:get').pause();

      this.port('in:elem').tap((n){
        this.port('in:get').resume();
      });

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

    static create() => new SetDataAttr();
    SetDataAttr(){
      this.meta('id','SetDataAttr');

      this.makeInport('in:key');
      this.makeInport('in:val');

      this.port('in:val').pause();
      this.port('in:key').forceCondition(Valids.isString);

      this.port('in:key').tap((n){
        this.key = key;
        this.port('in:val').resume();
      });

      this.port('in:val').tap((n){
        this.elem.setAttribute(this.key,n.data);
      });

    }
}

class DataAttr extends Component{

    static create() => new DataAttr();
    DataAttr(){
      this.meta('id','DataAttr');
      this.enableSubnet();

      this.makeInport('in:get');
      this.makeInport('in:elem');
      this.makeInport('in:set');
      this.makeInport('in:val');
      this.makeOutport('out:val');

      this.network.makeInport('in:get');
      this.network.makeInport('in:elem');
      this.network.makeInport('in:set');
      this.network.makeInport('in:val');
      this.network.makeOutport('out:val');
      
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

      this.network.add('elements/elements/GetDataAttr','getDataAttr');
      this.network.add('elements/elements/SetDataAttr','setDataAttr');
  
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
  
    static create() => new WriteHTML();
    WriteHTML(){
      this.makeInport('in:html');
      this.makeOutport('out:elem');

      this.port('in:html').forceCondition(Valids.isString);
      this.port('in:html').tap((n){
        this.elem.innerHTML = n.data;
        this.port('out:elem').send(this.elem);
      });
    }
}

class ReadHTML extends AttrCore{
  
    static create() => new ReadHTML();
    ReadHTML(){
      this.makeOutport('out:html');

      this.port('in:elem').tap((n){
        this.port('out:html').send(n.data.innerHTML);
      });
    }
}


class QuerySelector extends Component{
  html.Element e;

  static create() => new QuerySelector();

  QuerySelector(): super("QuerySelector"){
    
    this.createSpace('in');
    this.createSpace('out');

    this.makeInport('in:query');
    this.makeOutport('out:val');
    this.makeInport('in:elem');
  
    this.port('in:query').pause();


    this.port('in:elem').forceCondition(Elements.isElement);
    this.port('in:query').forceCondition(Valids.isString);
  
    this.port('in:elem').tap((p){ 
      this.e = p.data;  
    });

    this.port('in:elem').tap((e){ 
      this.port('in:query').resume(); 
    });

    this.port('in:query').tap((n){
      this.port('out:val').send(this.process(n));
    });
    
  }

  void process(n){
    return this.e.querySelector(n.data);
  }
}

class QuerySelectorAll extends QuerySelector{
  
    static create() => new QuerySelectorAll();
    QuerySelectorAll(): super(){
        this.meta('id',"QuerySelectorAll");
    }

    void process(n) => this.e.querySelectorAll(n.data);
}

class MapAttributable extends Component{
  String attr;
  
  static create(fn) => new MapAttributable(fn);
   
  MapAttributable(Function handle): super('MapAttributable'){

    this.createSpace('in');
    this.createSpace('out');

    this.makeInport('in:attr');
    this.makeInport('in:elem');
    this.makeOutport('out:elem');
    
    this.port('out:elem').pause();

    this.port('in:attr').forceCondition(Valids.isMap);
    this.port('in:attr').tap((n){ this.attr = n; });
    this.port('in:attr').tap((n){ this.port('out:elem').resume(); });
    
    this.port('in:elem').bindPort('out:elem');
     
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
