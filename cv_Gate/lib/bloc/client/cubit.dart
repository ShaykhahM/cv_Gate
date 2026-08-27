import 'package:bloc/bloc.dart';

import 'package:cv_gate/bloc/client/states.dart';
import 'package:cv_gate/screens/client/contracts/ClientContracts_Screen.dart';
import 'package:cv_gate/screens/client/dashboard/clientDashboard_Screen.dart';
import 'package:cv_gate/screens/client/freelancers/ClientFreelancers_Screen.dart';
import 'package:cv_gate/screens/client/jobs/ClientJobs_Screen.dart';
import 'package:cv_gate/screens/client/payments/ClientPayments_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientCubit extends Cubit<ClientState> {
  ClientCubit() : super(ClientInitialState());

  static ClientCubit get(context) => BlocProvider.of(context);

  List<Widget> clientScreens = [
    const ClientDashboardScreen(),
    const ClientJobsListScreen(),
    const ClientBrowseFreelancersScreen(),
    const ClientContractsListScreen(),
    const ClientPaymentsListScreen(),
  ];

  int currentScreen = 0;

  void changeScreen(int index) {
    currentScreen = index;
    emit(ClientChangeScreenState());
  }
}