import 'package:bloc/bloc.dart';
import 'package:cv_gate/bloc/admin%20bloc/states.dart';
import 'package:cv_gate/screens/Admin/Dashboard/AdminDashboard_Screen.dart';
import 'package:cv_gate/screens/Admin/Manage%20Jobs%20and%20Contract/AdminJobs_Layout.dart';
import 'package:cv_gate/screens/Admin/Manage%20Jobs%20and%20Contract/ManageJobs_Screen.dart';
import 'package:cv_gate/screens/Admin/Manage%20Payments%20and%20Disputed/AdminPaymentsDisputes_Layout.dart';
import 'package:cv_gate/screens/Admin/Manage%20Payments%20and%20isputes/ManagePayment_Screen.dart';
import 'package:cv_gate/screens/Admin/Manage%20Users/ManageUsers_Screen.dart';
import 'package:cv_gate/screens/Admin/Settings/Settings_Screen.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';



class AdminCubit extends Cubit<AdminState> {
  AdminCubit() :super(AdminInitalState());

  static AdminCubit get(context) => BlocProvider.of(context);

  bool isHide = true;

  // void changePass() {
  //   isHide = !isHide;
  //   emit(AdminChangePassState());
  // }


  List<Widget> adminScreens =
  [

    AdminPaymentsDisputesLayout(),
    ManageusersScreen(),
    AdminDashboardScreen(),
    AdminJobsLayout(),
    AdminSettingsScreen(),

  ];

  int currentScreen = 2;

  void changeScreen(index) {
    currentScreen = index;
    emit(AdminChangeScreenState());
  }


}