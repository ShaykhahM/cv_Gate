
import 'package:cv_gate/screens/Admin/Layout/AdminNavBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';



import '../../../bloc/admin bloc/cubit.dart';
import '../../../bloc/admin bloc/states.dart';


class AdminLayout extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCubit,AdminState>(
      listener: (context,state){},
      builder: (context,state)
      {
        AdminCubit cubit =AdminCubit.get(context);
        return Scaffold(
          body:cubit.adminScreens[cubit.currentScreen],

          bottomNavigationBar:  AdminNavBar(
              currentIndex: cubit.currentScreen,
              onTabChange: (index)
              {
                cubit.changeScreen(index);
              }),

        );
      },

    );
  }
}
