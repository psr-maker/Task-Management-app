import 'package:flutter/material.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/enum.dart';



class TaskUtils {
  
  static String getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return "Pending";
      case TaskStatus.inProgress:
        return "Inprogress";
      case TaskStatus.paused:
        return "Paused";
      case TaskStatus.completed:
        return "Completed";
      case TaskStatus.NotStarted:
        return "NotStarted";
    }
  }
 static TaskStatus parseStatus(String status) {
  final normalized = status.toLowerCase().trim().replaceAll('_', '');

  switch (normalized) {
    case "pending":
      return TaskStatus.pending;

    case "inprogress":
      return TaskStatus.inProgress;

    case "paused":
      return TaskStatus.paused;

    case "completed":
      return TaskStatus.completed;

    case "notstarted":
      return TaskStatus.NotStarted;

    default:
      return TaskStatus.NotStarted;
  }
}

  static Color getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.paused:
        return Colors.purple;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.NotStarted:
        return Colors.black54;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }


}


class droptaskutils {

  // ---------- STATUS ----------
  static List<String> getAllStatuses() {
    return [
      "Pending",
      "Inprogress",
      "Paused",
      "Completed",
      "Notstarted",
    ];
  }

  static String getStatusDisplayName(String status) {
    switch (AppHelpers.normalize(status)) {
      case "Pending":
        return "Pending";
      case "Inprogress":
        return "InProgress";
      case "Paused":
        return "Paused";
      case "Completed":
        return "Completed";
      case "Notstarted":
        return "NotStarted";
      default:
        return status;
    }
  }

  static Color getStatusColorFromString(String status) {
    switch (AppHelpers.normalize(status)) {
      case "Pending":
        return Colors.orange;
      case "Inprogress":
        return Colors.blue;
      case "Paused":
        return Colors.purple;
      case "Completed":
        return Colors.green;
      case "Notstarted":
        return Colors.black54;
      default:
        return Colors.grey;
    }
  }

  // ---------- PRIORITY ----------
  static List<String> getAllPriorities() {
    return ["Normal", "Medium", "High"];
  }

  static String getPriorityDisplayName(String priority) {
    switch (priority.toLowerCase().trim()) {
      case "Normal":
        return "Normal";
      case "Medium":
        return "Medium";
      case "High":
        return "High";
      default:
        return priority;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase().trim()) {
      case "Normal":
        return Colors.green;
      case "Medium":
        return Colors.orange;
      case "High":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}



