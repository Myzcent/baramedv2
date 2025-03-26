// screen/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade600,
        title: Text(
          "Calendar",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 15),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {CalendarFormat.month: "Month"},
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.teal),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.teal),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.add, color: Colors.white),
            label: Text("Add Schedule", style: TextStyle(fontSize: 16)),

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (_selectedDay != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Schedule added on ${_selectedDay!.toLocal()}",
                    ),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.home_outlined, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              IconButton(
                icon: Icon(Icons.calendar_today, size: 28, color: Colors.teal),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.message_outlined, size: 28),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.person_outline, size: 28),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
