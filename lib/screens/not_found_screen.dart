import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  final String location;
  const NotFoundScreen({super.key, required this.location});
  @override
  Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFFFFF7FA),body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Icon(Icons.pets,size:64,color:Color(0xFFB85C83)),const SizedBox(height:12),
    const Text('Кажется, эта дорожка потерялась 🐾',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
    const SizedBox(height:8),Text('Страница «$location» не найдена.',textAlign:TextAlign.center),
    const SizedBox(height:20),FilledButton(onPressed:()=>context.go('/'),child:const Text('На главную')),
  ]))));
}
