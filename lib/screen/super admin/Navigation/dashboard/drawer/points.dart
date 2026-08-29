import 'package:flutter/material.dart';

class ProductivityCalculationPage extends StatelessWidget {
  const ProductivityCalculationPage({super.key});

  static const Color card = Color.fromARGB(255, 13, 40, 22);
  static const Color cardLight = Color.fromARGB(255, 19, 52, 29);
  static const Color primary = Color.fromARGB(255, 25, 77, 38);
  static const Color border = Color.fromARGB(255, 42, 72, 48);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 247, 215),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 26, 53, 24),
         leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Calculation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 3),
            Text(
              'How monthly productivity is calculated',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 40 : 16,
              vertical: 10,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _monthlyHeader(),

                    const SizedBox(height: 30),

                    _sectionHeader(
                      '01',
                      'Staff Productivity',
                      'Individual staff monthly score',
                    ),

                    const SizedBox(height: 14),

                    _staffWeightage(),

                    const SizedBox(height: 25),

                    _subHeader('A. Task Score'),

                    const SizedBox(height: 10),

                    _taskCalculation(),

                    const SizedBox(height: 12),

                    _taskPriority(),

                    const SizedBox(height: 12),

                    _taskTime(),

                    const SizedBox(height: 12),

                    _taskPenalty(),

                    const SizedBox(height: 12),

                    _monthlyTaskScore(),

                    const SizedBox(height: 25),

                    _subHeader('B. Goal Score'),

                    const SizedBox(height: 10),

                    _goalCalculation(),

                    const SizedBox(height: 12),

                    _goalPriority(),

                    const SizedBox(height: 12),

                    _goalTime(),

                    const SizedBox(height: 25),

                    _subHeader('C. Attitude & Behaviour'),

                    const SizedBox(height: 10),

                    _attitude(),

                    const SizedBox(height: 25),

                    _subHeader('D. Final Staff Productivity'),

                    const SizedBox(height: 10),

                    _staffFinal(),

                    const SizedBox(height: 40),

                    _sectionHeader(
                      '02',
                      'Department Productivity',
                      'Department-level monthly score',
                    ),

                    const SizedBox(height: 14),

                    _departmentWeightage(),

                    const SizedBox(height: 25),

                    _subHeader('A. Department Task'),

                    const SizedBox(height: 10),

                    _departmentTask(),

                    const SizedBox(height: 25),

                    _subHeader('B. Department Goal'),

                    const SizedBox(height: 10),

                    _departmentGoal(),

                    const SizedBox(height: 25),

                    _subHeader('C. Department Attitude & Behaviour'),

                    const SizedBox(height: 10),

                    _departmentAttitude(),

                    const SizedBox(height: 25),

                    _subHeader('D. Department 5S'),

                    const SizedBox(height: 10),

                    _department5S(),

                    const SizedBox(height: 25),

                    _subHeader('E. Final Department Score'),

                    const SizedBox(height: 10),

                    _departmentFinal(),

                    const SizedBox(height: 30),

                    // _bottomNote(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _monthlyHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 25, 77, 38),
            Color.fromARGB(255, 10, 42, 20),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        children: [
          Icon(Icons.analytics_outlined, size: 34),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONTHLY PERFORMANCE SCORE',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '100 Points',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Maximum monthly score',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String number, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            number,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
      ],
    );
  }

  Widget _subHeader(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _staffWeightage() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('STAFF WEIGHTAGE'),

          const SizedBox(height: 15),

          const Text(
            'The weightage changes depending on whether the staff member '
            'has tasks, goals, or both.',
            style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.5),
          ),

          const SizedBox(height: 18),

          // BOTH
          _weightCase(
            title: 'TASK + GOAL EXIST',
            task: '45',
            goal: '40',
            attitude: '15',
            total: '100',
          ),

          const SizedBox(height: 10),

          // TASK ONLY
          _weightCase(
            title: 'ONLY TASK EXISTS',
            task: '85',
            goal: '0',
            attitude: '15',
            total: '100',
            highlighted: true,
          ),

          const SizedBox(height: 10),

          // GOAL ONLY
          _weightCase(
            title: 'ONLY GOAL EXISTS',
            task: '0',
            goal: '85',
            attitude: '15',
            total: '100',
            highlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _weightCase({
    required String title,
    required String task,
    required String goal,
    required String attitude,
    required String total,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? primary.withOpacity(.28) : cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlighted ? primary : border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              letterSpacing: .8,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _weightItem('TASK', task)),
              Expanded(child: _weightItem('GOAL', goal)),
              Expanded(child: _weightItem('ATTITUDE', attitude)),
              Expanded(child: _weightItem('TOTAL', total)),
            ],
          ),

          if (highlighted) ...[
            const SizedBox(height: 12),
            const Text(
              'The available Task/Goal component receives the full 85 points.',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _weightItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 9, color: Colors.white38)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _taskCalculation() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('MONTHLY TASK AVERAGE'),

          const SizedBox(height: 15),

          _formulaBox(
            'Task 1 + Task 2 + Task 3 + ...',
            'Total Tasks in Month',
            'Monthly Task Average',
          ),

          const SizedBox(height: 14),

          _info(
            'Each task score is calculated using its time score and priority score.',
          ),
        ],
      ),
    );
  }

  Widget _taskPriority() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('TASK PRIORITY SCORE'),

          const SizedBox(height: 14),

          _scoreRow('High Priority', '+5'),

          _scoreRow('Medium Priority', '+3'),

          _scoreRow('Normal Priority', '+0'),

          const SizedBox(height: 8),

          _formulaResult('Time Score + Priority Score', 'TASK SCORE'),
        ],
      ),
    );
  }

  Widget _taskTime() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('TASK TIME SCORE'),

          const SizedBox(height: 14),

          _scoreRow('Before due date', '100'),
          _scoreRow('On due date', '95'),
          _scoreRow('1 day late', '90'),
          _scoreRow('2 days late', '85'),
          _scoreRow('3 days late', '80'),
          _scoreRow('Each additional late day', '-5'),

          const SizedBox(height: 7),

          _info('Minimum time score is 50 points.'),
        ],
      ),
    );
  }

  Widget _taskPenalty() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('TASK REMOVAL PENALTY'),

          const SizedBox(height: 14),

          _scoreRow('High Priority task removed', '-10'),
          _scoreRow('Medium Priority task removed', '-5'),
          _scoreRow('Normal Priority task removed', '-3'),

          const SizedBox(height: 8),

          _info(
            'Removal penalties are deducted from the monthly task average.',
          ),
        ],
      ),
    );
  }

  Widget _monthlyTaskScore() {
    return _highlight(
      title: 'MONTHLY TASK SCORE',

      formula: 'Monthly Task Average − Monthly Task Removal Penalty',

      result: 'This score is used to calculate Final Task Points.',
    );
  }

  Widget _goalCalculation() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('GOAL SCORE'),

          const SizedBox(height: 15),

          _formulaBox(
            'Task 1 + Task 2 + Task 3 + ...',
            'Total Tasks in Goal',
            'Goal Task Average',
          ),

          const SizedBox(height: 16),

          _formulaResult(
            'Goal Task Average + Priority + Time Score',
            'GOAL POINTS',
          ),

          const SizedBox(height: 12),

          _info(
            'The goal points are calculated from the tasks belonging to that goal.',
          ),
        ],
      ),
    );
  }

  Widget _goalPriority() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('GOAL PRIORITY'),

          const SizedBox(height: 14),

          _scoreRow('High Priority', '+5'),
          _scoreRow('Medium Priority', '+3'),
          _scoreRow('Normal Priority', '+0'),
        ],
      ),
    );
  }

  Widget _goalTime() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('GOAL TIME SCORE'),

          const SizedBox(height: 14),

          _scoreRow('Before due date', '+5'),
          _scoreRow('On due date', '+5'),
          _scoreRow('1 day late', '-5'),
          _scoreRow('2 days late', '-10'),
          _scoreRow('3 days late', '-15'),

          const SizedBox(height: 7),

          _info(
            'Every additional late day reduces the goal time score by 5 points.',
          ),
        ],
      ),
    );
  }

  Widget _attitude() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('ATTITUDE & BEHAVIOUR'),

          const SizedBox(height: 15),

          _formulaBox(
            'Staff Attitude & Behaviour Scores',
            'Number of Staff Scores',
            'Average Attitude & Behaviour',
          ),

          const SizedBox(height: 15),

          _resultBox('Maximum Contribution', '15 points'),
        ],
      ),
    );
  }

  Widget _staffFinal() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('FINAL STAFF PRODUCTIVITY'),

          const SizedBox(height: 18),

          // BOTH
          _finalFormula(
            'If Task + Goal exist',
            'Task: (Monthly Task Score ÷ 100) × 45',
            'Goal: (Monthly Goal Score ÷ 100) × 40',
          ),

          const SizedBox(height: 12),

          // TASK ONLY
          _finalFormula(
            'If ONLY Task exists',
            'Task: (Monthly Task Score ÷ 100) × 85',
            'Goal: 0',
            highlighted: true,
          ),

          const SizedBox(height: 12),

          // GOAL ONLY
          _finalFormula(
            'If ONLY Goal exists',
            'Task: 0',
            'Goal: (Monthly Goal Score ÷ 100) × 85',
            highlighted: true,
          ),

          const SizedBox(height: 18),

          _calculationBox(
            'FINAL FORMULA',
            'Final Task Points + Final Goal Points + Attitude & Behaviour',
            'MAXIMUM = 100',
          ),
        ],
      ),
    );
  }

  Widget _departmentWeightage() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('DEPARTMENT WEIGHTAGE'),

          const SizedBox(height: 16),

          _weightLine('Department Task', '40'),
          _weightLine('Department Goal', '35'),
          _weightLine('Attitude & Behaviour', '15'),
          _weightLine('Department 5S', '10'),

          const Divider(color: border, height: 25),

          _weightLine('TOTAL', '100', bold: true),
        ],
      ),
    );
  }

  Widget _departmentTask() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('DEPARTMENT TASK'),

          const SizedBox(height: 15),

          _formulaBox(
            'All Staff Monthly Task Points',
            'Number of Staff',
            'Average Staff Task Points',
          ),

          const SizedBox(height: 16),

          _formulaResult(
            '(Average Staff Task Points ÷ 45) × 40',
            'DEPARTMENT TASK',
          ),

          const SizedBox(height: 12),

          _info('Department Task is based on the 45-point staff Task weight.'),
        ],
      ),
    );
  }

  Widget _departmentGoal() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('DEPARTMENT GOAL'),

          const SizedBox(height: 15),

          _formulaBox(
            'All Staff Monthly Goal Points',
            'Number of Staff',
            'Average Staff Goal Points',
          ),

          const SizedBox(height: 16),

          _formulaResult(
            '(Average Staff Goal Points ÷ 40) × 35',
            'DEPARTMENT GOAL',
          ),

          const SizedBox(height: 12),

          _info('Department Goal is based on the 40-point staff Goal weight.'),
        ],
      ),
    );
  }

  Widget _departmentAttitude() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('DEPARTMENT ATTITUDE & BEHAVIOUR'),

          const SizedBox(height: 15),

          _formulaBox(
            'All Staff Attitude & Behaviour Scores',
            'Number of Staff',
            'Average Attitude & Behaviour',
          ),

          const SizedBox(height: 14),

          _resultBox('Maximum Contribution', '15 points'),
        ],
      ),
    );
  }

  Widget _department5S() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('DEPARTMENT 5S'),

          const SizedBox(height: 15),

          _formulaBox(
            'W1 + W2 + W3 + ...',
            'Number of 5S Assessments',
            'Average 5S Score',
          ),

          const SizedBox(height: 16),

          _formulaResult('(Average 5S Score ÷ 100) × 10', 'DEPARTMENT 5S'),

          const SizedBox(height: 12),

          _info('5S contributes a maximum of 10 points.'),
        ],
      ),
    );
  }

  Widget _departmentFinal() {
    return _card(
      child: Column(
        children: [
          _label('TOTAL DEPARTMENT SCORE'),

          const SizedBox(height: 18),

          _weightLine('Department Task', '40'),
          _weightLine('Department Goal', '35'),
          _weightLine('Attitude & Behaviour', '15'),
          _weightLine('Department 5S', '10'),

          const SizedBox(height: 15),

          _calculationBox(
            'FINAL FORMULA',
            'Department Task + Department Goal + '
                'Attitude & Behaviour + Department 5S',
            'MAXIMUM = 100',
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        color: Colors.white54,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _formulaBox(String numerator, String denominator, String result) {
    return Column(
      children: [
        _formulaPart(numerator),

        const SizedBox(height: 4),

        const Text('÷', style: TextStyle(fontSize: 18, color: Colors.white38)),

        const SizedBox(height: 4),

        _formulaPart(denominator, dark: true),

        const SizedBox(height: 8),

        const Icon(Icons.arrow_downward, size: 17, color: Colors.white38),

        const SizedBox(height: 7),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primary.withOpacity(.45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            result,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _formulaPart(String text, {bool dark = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withOpacity(.10) : cardLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: dark ? Colors.white54 : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _scoreRow(String title, String score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.white54),
          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primary.withOpacity(.40),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              score,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulaResult(String formula, String result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withOpacity(.30),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            formula,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 8),

          const Icon(Icons.arrow_downward, size: 16, color: Colors.white38),

          const SizedBox(height: 5),

          Text(
            result,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlight({
    required String title,
    required String formula,
    required String result,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary.withOpacity(.40),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(title),

          const SizedBox(height: 12),

          Text(
            formula,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            result,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _info(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBox(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primary.withOpacity(.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _finalFormula(
    String title,
    String line1,
    String line2, {
    bool highlighted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted
            ? primary.withOpacity(.35)
            : Colors.black.withOpacity(.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: highlighted ? primary : border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            line1,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),

          const SizedBox(height: 5),

          Text(
            line2,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _calculationBox(String title, String formula, String result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white60,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            formula,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 10),

          const Divider(color: Colors.white24),

          const SizedBox(height: 8),

          Text(
            result,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightLine(String title, String points, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '$points points',
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _bottomNote() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.yellow.withOpacity(.06),
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(color: Colors.yellow),
  //     ),
  //     child: const Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Icon(Icons.info_outline, size: 19, color: Colors.yellow),
  //         SizedBox(width: 10),
  //         Expanded(
  //           child: Text(
  //             'Important: Staff productivity always includes '
  //             'Attitude & Behaviour (15 points). If both Task and Goal '
  //             'exist, they use 45 + 40 points. If only one exists, '
  //             'that component receives 85 points. Department 5S is '
  //             'calculated separately and contributes 10 points to the '
  //             'department score.',
  //             style: TextStyle(
  //               fontSize: 11,
  //               color: Colors.black87,
  //               height: 1.5,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
