import 'package:flutter/material.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Admin/admintab.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Employee/emptab.dart';

class Usersview extends StatelessWidget {
  const Usersview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor:  Color.fromARGB(255, 25, 77, 38),
     body:  
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              SizedBox(height: 50),
              TabBar(
                indicatorSize: TabBarIndicatorSize.tab, 
                
                indicatorPadding: const EdgeInsets.only(left: 50,right: 50,top: 8,bottom: 8),
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                labelColor:Color.fromARGB(255, 25, 77, 38),
                unselectedLabelColor: Colors.white,
                labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Manager'),
                  Tab(text: 'Staff'),
                ],
              ),
        
              Expanded(child: TabBarView(children: [Admintab(), Employeetab()])),
            ],
          ),
        ),
      
    );
  }
}
