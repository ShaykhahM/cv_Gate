import 'package:cv_gate/bloc/admin%20bloc/cubit.dart';
import 'package:cv_gate/bloc/client/cubit.dart';
import 'package:cv_gate/bloc/freelancer%20bloc/cubit.dart';
import 'package:cv_gate/screens/auth/login_screen.dart';
import 'package:cv_gate/screens/splash/Splash_Screen.dart';

import 'package:cv_gate/shared/services/local/Cahs_Helper.dart';
import 'package:cv_gate/test_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


Future<void> main()async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait<void>([
    Firebase.initializeApp(),
    CashHelper.initPreference(),
  ]);
  Widget widget;
  var userTypeIndex =CashHelper.getCash(key: 'userIndex');

  // tempId=CashHelper.getCash(key: 'token');
  //
  // if(tempId !=null)
  // {
  //   userID=tempId!;
  // }


  if(userTypeIndex != null)
  {
    widget=SplashScreen(userTypeIndex);
  }
  else
  {

    widget=SplashScreen(0);
  }
  runApp( MyApp(widget));
}

class MyApp extends StatelessWidget {
  Widget screen;
  MyApp(this.screen);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers:
      [
        BlocProvider(create: (context)=>AdminCubit()),
        BlocProvider(create: (context)=>FreelancerCubit()),
        BlocProvider(create: (context)=>ClientCubit()),
      ],
      child: MaterialApp(
        title: 'CVGATE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Janna',
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0A2A43)),
          useMaterial3: true,
        ),
        home: screen,

      ),
    );
  }
}
