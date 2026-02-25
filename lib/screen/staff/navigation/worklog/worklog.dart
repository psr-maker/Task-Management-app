import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/addworklog.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';

class Worklog extends StatefulWidget {
  const Worklog({super.key});

  @override
  State<Worklog> createState() => _WorklogState();
}

class _WorklogState extends State<Worklog> {
  bool _isLoading = false;

  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> logs = [];
 
  Duration calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return Duration(minutes: endMinutes - startMinutes);
  }

  String formatDuration(Duration d) {
    return "${d.inHours}h ${d.inMinutes % 60}m";
  }

  Duration totalDuration() {
    Duration total = Duration.zero;
    for (var log in logs) {
      total += calculateDuration(log["start"], log["end"]);
    }
    return total;
  }

  void _pickYearMonthDate() {
    int tempYear = selectedDate.year;
    int tempMonth = selectedDate.month;
    int tempDay = selectedDate.day;

    int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color.fromARGB(255, 10, 54, 12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int maxDays = daysInMonth(tempYear, tempMonth);
            if (tempDay > maxDays) tempDay = maxDays;

            return Padding(
              padding: EdgeInsets.only(
                left: 15,
                right: 15,
                top: 15,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Date",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Year",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      DropdownButton<int>(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        value: tempYear,

                        items: List.generate(27, (i) {
                          int year = DateTime.now().year - i;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (v) => setModalState(() => tempYear = v!),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Month",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      DropdownButton<int>(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        value: tempMonth,
                        items: List.generate(12, (i) {
                          return DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              DateFormat('MMMM').format(DateTime(0, i + 1)),
                            ),
                          );
                        }),
                        onChanged: (v) => setModalState(() => tempMonth = v!),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 200,
                    child: GridView.builder(
                      itemCount: maxDays,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemBuilder: (context, index) {
                        int day = index + 1;
                        bool isSelected = day == tempDay;

                        return GestureDetector(
                          onTap: () => setModalState(() => tempDay = day),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(width: 2, color: Colors.white),
                              color: isSelected
                                  ? Colors.white
                                  : Color.fromARGB(255, 10, 54, 12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: AppButton(
                      text: "Apply",
                      isLoading: _isLoading,
                      onPressed: () {
                        setState(() {
                          selectedDate = DateTime(tempYear, tempMonth, tempDay);
                        });
                        Navigator.pop(context);
                      },

                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addWorklog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddWorklogPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        logs.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
    
        title: const Text(
          "Daily Worklog",
         
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
           
            _weekHeader(),
            SizedBox(height: 10),
            _totalHours(),
            SizedBox(height: 10),
            Expanded(child: _timelineLogs()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 25, 77, 38),
        onPressed: _addWorklog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _weekHeader() {
    DateTime startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 25, 77, 38),
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                    style: TextStyle(
                      color: const Color.fromARGB(255, 25, 77, 38),
                      fontSize: 10,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),

              IconButton(
                onPressed: _pickYearMonthDate,
                icon: Icon(
                  Icons.edit_calendar_outlined,
                  color: const Color.fromARGB(255, 25, 77, 38),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                DateTime day = startOfWeek.add(Duration(days: index));
                bool isSelected =
                    day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day;

                return GestureDetector(
                  onTap: () => setState(() => selectedDate = day),
                  child: Container(
                    width: 45,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color.fromARGB(255, 62, 98, 64)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(day).substring(0, 1),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color.fromARGB(255, 108, 143, 117),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color.fromARGB(255, 25, 77, 38),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineLogs() {
    if (logs.isEmpty) {
      return const Center(child: Text("No worklogs yet."));
    }

    return ListView.builder(
    
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final duration = calculateDuration(log["start"], log["end"]);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            SizedBox(
              width: 50,
              height: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    log["start"].format(context),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 10, 54, 12),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    log["end"].format(context),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 10, 54, 12),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 10, 54, 12),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 60,
                  color: Color.fromARGB(255, 74, 117, 77),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                color: Color.fromARGB(255, 134, 170, 136),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log["description"] ?? "No description",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 10, 54, 12),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        "Duration: ${formatDuration(duration)}",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 7, 53, 1),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _totalHours() {
    final total = totalDuration();
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 25, 77, 38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total Work Time",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          Text(
            formatDuration(total),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
