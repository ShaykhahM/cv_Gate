import 'package:bloc/bloc.dart';
import 'package:cv_gate/bloc/freelancer%20bloc/states.dart';
import 'package:cv_gate/screens/freelancer/Works/FreelancerWork_Screen.dart';

import 'package:cv_gate/screens/freelancer/dashbord/FreelancerDashboard_Screen.dart';
import 'package:cv_gate/screens/freelancer/jobs/FreelancerJobs_Layout.dart';

import 'package:cv_gate/screens/freelancer/payments/FreelancerPayments_Screen.dart';
import 'package:cv_gate/screens/freelancer/reviews/FreelancerReviews_Screen.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FreelancerCubit extends Cubit<FreelancerState> {
  FreelancerCubit() : super(FreelancerInitialState());

  static FreelancerCubit get(context) => BlocProvider.of(context);

  List<Widget> freelancerScreens = [


    ContractsListScreen(freelancerId: freelancerId,),
    FreelancerJobsLayout(freelancerId:freelancerId,),
    FreelancerDashboardScreen(freelancerId: freelancerId,),
    PaymentsListScreen(freelancerId: freelancerId,),
     FreelancerReviewsScreen(freelancerId: freelancerId,),
  ];

  int currentScreen = 2;

  void changeScreen(int index) {
    currentScreen = index;
    emit(FreelancerChangeScreenState());
  }
}