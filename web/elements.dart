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

    SparkRegistry.generate('elements/getAttr').boot().then((get){

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
    
        SparkRegistry.generate('elements/setAttr').boot().then((set){
        
          set.port('in:elem').send(a);
          set.port('in:key').send('id');
          set.port('in:val').send('thunder');
          
          set.port('in:key').send('class');
          set.port('in:val').send('page-section');
        });

        SparkRegistry.generate('elements/Attr').boot().then((attr){
        
          attr.port('out:value').tap(packetPrint);
          attr.port('in:elem').send(a);

          attr.port('in:get').send('id');
          attr.port('in:get').send('class');

        });
    
    });


}
