library spark_elements.specs;

import 'dart:html';
import 'package:sparkflow/sparkflow.dart';
import 'package:hub/hubclient.dart';
import 'package:spark_elements/elements.dart' as e;

void main(){
    

    e.Elements.registerComponents();

    var packetPrint = Funcs.compose(window.document.body.append,(n){
        return new Element.html('<pre>$n</pre>');
    });

    var a = new Element.div();
    window.document.body.append(a);

    a.setAttribute('id','chiken');
    a.setAttribute('class','frozen');
    a.style.width = '400px';
    a.style.height = '100px';
    a.style.background = "#222";

    SparkFlow.registry.ns('html').generate('dom/element').boot().then((elem){

        elem.port('in:elem').send(a);
        elem.port('events:sub').send('click');
        elem.port('out:elem').tap(packetPrint);
        elem.port('events:events').tap(packetPrint);
    });

    SparkFlow.registry.ns('html').generate('dom/getAttr').boot().then((get){

      get.port('in:elem').send(a);
      get.port('out:value').tap(packetPrint);

      get.port('in:get').send('id');
    
      //stops all transmission
      return get.shutdown().then((n){

        //queues this up for next reboot
        get.port('in:get').send('class');

        return get.boot();
      
      });
    
    }).then((get){
    


        SparkFlow.registry.ns('html').generate('dom/setAttr').boot().then((set){
        
          set.port('in:elem').send(a);
          set.port('in:key').send('id');
          set.port('in:val').send('thunder');
          
          set.port('in:key').send('class');
          set.port('in:val').send('page-section');
        });

        SparkFlow.registry.ns('html').generate('dom/Attr').boot().then((attr){
        
          attr.port('out:value').tap(packetPrint);
          attr.port('in:elem').send(a);

          attr.port('in:get').send('id');
          attr.port('in:get').send('class');

        });

        SparkFlow.registry.ns('html').generate('dom/css').boot().then((css){
            css.port('in:elem').send(a);
            
            css.port('out:val').tap(packetPrint);

            css.port('in:get').send('width');

            css.port('in:key').send('width');
            css.port('in:val').send('200px');

            css.port('in:get').send('width');
        });
      

    });


}
