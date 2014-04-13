library spark_elements.specs;

import 'dart:html';
import 'package:sparkflow/sparkflow.dart';
import 'package:spark_elements/elements.dart' as e;

void main(){
    
    e.Elements.registerComponents();

    var a = new Element.div();
    a.setAttribute('id','chiken');
    a.setAttribute('class','frozen');

    var get = SparkRegistry.generate('elements/getattr');
    var set = SparkRegistry.generate('elements/setattr');
    
    get.boot();
    set.boot();

    get.port('in:elem').send(a);
    set.port('in:elem').send(a);

    get.port('out:value').tap(print);

    get.port('in:get').send('id');
  
    //stops all transmission
    get.shutdown();
    
    //queues this up for next reboot
    get.port('in:get').send('class');

    get.boot();


    var attr = SparkRegistry.generate('elements/Attr');

}
