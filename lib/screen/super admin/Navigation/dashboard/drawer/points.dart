import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';

class ProductivityCalculationPage extends StatefulWidget {
  const ProductivityCalculationPage({super.key});

  @override
  State<ProductivityCalculationPage> createState() =>
      _ProductivityCalculationPageState();
}

class _ProductivityCalculationPageState extends State<ProductivityCalculationPage> {
  Color get primary => WebTheme.brandOf(context);
  Color get card => WebTheme.surfaceOf(context);
  Color get cardLight => WebTheme.brandSoftOf(context);
  Color get border => WebTheme.lineOf(context);
  Color get ink => WebTheme.inkOf(context);
  Color get muted => WebTheme.mutedOf(context);
  int _webTab = 0;

  @override
  Widget build(BuildContext context) {
    if (WebPushedChrome.isWeb(context)) return _webScaffold();
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),

      appBar: AppBar(
        backgroundColor: WebPushedChrome.isWeb(context)
            ? WebTheme.canvasOf(context)
            : Color.fromARGB(255, 26, 53, 24),
         leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: WebPushedChrome.isWeb(context)
            ? null
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Calculation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 3),
            Text(
              'How monthly productivity is calculated',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),

      body: WebPushedChrome.body(
        context,
        title: 'Score Calculation',
        subtitle: 'How monthly productivity is calculated',
        panel: false,
        child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 24 : 12,
              vertical: 10,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _monthlyHeader(),

                    SizedBox(height: 30),

                    _sectionHeader(
                      '01',
                      'Staff Productivity',
                      'Individual staff monthly score',
                    ),

                    SizedBox(height: 14),

                    _staffWeightage(),

                    SizedBox(height: 25),

                    _subHeader('A. Task Score'),

                    SizedBox(height: 10),

                    WebResponsiveRow(
                      minChildWidth: 420,
                      children: [
                        _taskCalculation(),
                        _taskPriority(),
                      ],
                    ),

                    SizedBox(height: 12),

                    WebResponsiveRow(
                      minChildWidth: 420,
                      children: [
                        _taskTime(),
                        _taskPenalty(),
                      ],
                    ),

                    SizedBox(height: 12),

                    _taskQuantity(),

                    SizedBox(height: 12),

                    _monthlyTaskScore(),

                    SizedBox(height: 25),

                    _subHeader('B. Goal Score'),

                    SizedBox(height: 10),

                    WebResponsiveRow(
                      minChildWidth: 420,
                      children: [
                        _goalCalculation(),
                        _goalPriority(),
                      ],
                    ),

                    SizedBox(height: 12),

                    _goalTime(),

                    SizedBox(height: 25),

                    _subHeader('C. Attitude & Behaviour'),

                    SizedBox(height: 10),

                    _attitude(),

                    SizedBox(height: 25),

                    _subHeader('D. Final Staff Productivity'),

                    SizedBox(height: 10),

                    _staffFinal(),

                    SizedBox(height: 40),

                    _sectionHeader(
                      '02',
                      'Department Productivity',
                      'Department-level monthly score',
                    ),

                    SizedBox(height: 14),

                    _departmentWeightage(),

                    SizedBox(height: 25),

                    _subHeader('A–B. Department Task & Goal'),

                    SizedBox(height: 10),

                    WebResponsiveRow(
                      minChildWidth: 420,
                      children: [
                        _departmentTask(),
                        _departmentGoal(),
                      ],
                    ),

                    SizedBox(height: 25),

                    _subHeader('C–D. Attitude, Behaviour & 5S'),

                    SizedBox(height: 10),

                    WebResponsiveRow(
                      minChildWidth: 420,
                      children: [
                        _departmentAttitude(),
                        _department5S(),
                      ],
                    ),

                    SizedBox(height: 25),

                    _subHeader('E. Final Department Score'),

                    SizedBox(height: 10),

                    _departmentFinal(),

                    SizedBox(height: 30),

                    // _bottomNote(),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _webScaffold() {
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back, color: ink),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score calculation',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'How the monthly score is built, out of 100',
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                    ],
                  ),
                ),
                _webTabs(),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 860;
                        return _webTab == 0
                            ? _webStaff(wide)
                            : _webDepartment(wide);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _webTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _webTabButton('Staff', 0),
          _webTabButton('Department', 1),
        ],
      ),
    );
  }

  Widget _webTabButton(String label, int index) {
    final selected = _webTab == index;
    return Material(
      color: selected ? primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _webTab = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _webStaff(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _webIntro(
          'Staff score',
          'Each person is scored from tasks, goals, and attitude. The mix changes when a person has only tasks or only goals.',
        ),
        const SizedBox(height: 14),
        _webSplit(wide, [
          _weightCard('Task and goal', const [
            ('Task', '45'),
            ('Goal', '40'),
            ('Attitude', '15'),
          ]),
          _weightCard('Task only', const [
            ('Task', '85'),
            ('Goal', '0'),
            ('Attitude', '15'),
          ]),
          _weightCard('Goal only', const [
            ('Task', '0'),
            ('Goal', '85'),
            ('Attitude', '15'),
          ]),
        ]),
        const SizedBox(height: 22),
        Text('Task', style: _webHeading()),
        const SizedBox(height: 10),
        _webSplit(wide, [
          _ruleTable('Time score', const [
            ('Before due date', '90'),
            ('On due date', '85'),
            ('1 day late', '80'),
            ('2 days late', '75'),
            ('3 days late', '70'),
            ('4 days late', '65'),
            ('5 days late', '60'),
            ('6 days late', '55'),
            ('7 or more days late', '50'),
          ], note: 'A task with an end time uses hours: 90 before, 85 on time, then minus 5 for each late hour. The score stays between 50 and 90.'),
          Column(
            children: [
              _ruleTable('Priority added to the time score', const [
                ('High', '+5'),
                ('Medium', '+3'),
                ('Normal', '+0'),
              ]),
              const SizedBox(height: 12),
              _ruleTable('Removal penalty, taken off the monthly average', const [
                ('High priority removed', '-10'),
                ('Medium priority removed', '-5'),
                ('Normal priority removed', '-3'),
              ]),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        _formulaPanel(
          'Quantity',
          'Task score × completed quantity ÷ target quantity',
          'No target uses time + priority. Missing completed quantity is 0. At or above target keeps the full task score. Example: 90 × 6 ÷ 10 = 54.',
        ),
        const SizedBox(height: 12),
        _formulaPanel(
          'Monthly task score',
          'Average of task scores − removal penalties',
          'Average = (Task 1 + Task 2 + …) ÷ tasks in the month. This score feeds the final task points.',
        ),
        const SizedBox(height: 22),
        Text('Goal and attitude', style: _webHeading()),
        const SizedBox(height: 10),
        _webSplit(wide, [
          _formulaPanel(
            'Goal points',
            'Average of the goal’s tasks + priority + time',
            'Task average = (Task 1 + Task 2 + …) ÷ tasks in the goal. Priority is +5 high, +3 medium, +0 normal.',
          ),
          _ruleTable('Goal time', const [
            ('Before or on due date', '+5'),
            ('1 day late', '-5'),
            ('2 days late', '-10'),
            ('3 days late', '-15'),
          ], note: 'Each extra late day takes off another 5 points.'),
        ]),
        const SizedBox(height: 12),
        _formulaPanel(
          'Attitude and behaviour',
          'Sum of scores ÷ number of scores',
          'Maximum contribution is 15 points.',
        ),
        const SizedBox(height: 12),
        _finalPanel(
          'Final staff score',
          const [
            ('Task and goal', 'Task (score ÷ 100) × 45  +  Goal (score ÷ 100) × 40  +  attitude'),
            ('Task only', 'Task (score ÷ 100) × 85  +  attitude'),
            ('Goal only', 'Goal (score ÷ 100) × 85  +  attitude'),
          ],
          'Maximum 100',
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _webSplit(bool wide, List<Widget> children) {
    if (!wide) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _webDepartment(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _webIntro(
          'Department score',
          'The department score averages the staff results, then applies a fixed weight. The total is still 100.',
        ),
        const SizedBox(height: 14),
        _webSplit(wide, [
          _pointTile('Task', '40'),
          _pointTile('Goal', '35'),
          _pointTile('Attitude', '15'),
          _pointTile('5S', '10'),
        ]),
        const SizedBox(height: 14),
        _webSplit(wide, [
          _formulaPanel(
            'Department task',
            '(Average staff task points ÷ 45) × 40',
            'Average = all staff monthly task points ÷ number of staff. The 45 is the staff task weight.',
          ),
          _formulaPanel(
            'Department goal',
            '(Average staff goal points ÷ 40) × 35',
            'Average = all staff monthly goal points ÷ number of staff. The 40 is the staff goal weight.',
          ),
        ]),
        const SizedBox(height: 12),
        _webSplit(wide, [
          _formulaPanel(
            'Attitude and behaviour',
            'All staff attitude scores ÷ number of staff',
            'Maximum contribution is 15 points.',
          ),
          _formulaPanel(
            'Department 5S',
            '(Average 5S score ÷ 100) × 10',
            'Average = (W1 + W2 + W3 + …) ÷ number of 5S assessments. Maximum is 10 points.',
          ),
        ]),
        const SizedBox(height: 12),
        _finalPanel(
          'Final department score',
          const [
            ('Total', 'Department task + department goal + attitude + 5S'),
          ],
          'Maximum 100',
        ),
      ],
    );
  }

  TextStyle _webHeading() {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: ink,
    );
  }

  Widget _webIntro(String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WebTheme.brandSoftOf(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '100',
              style: TextStyle(
                color: primary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: muted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightCard(String title, List<(String, String)> parts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final part in parts)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(part.$1, style: TextStyle(color: muted, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        part.$2,
                        style: TextStyle(
                          color: ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pointTile(String label, String points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            points,
            style: TextStyle(color: primary, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          Text('points', style: TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _ruleTable(String title, List<(String, String)> rows, {String? note}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1, style: TextStyle(color: ink, fontSize: 13))),
                  Text(
                    row.$2,
                    style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Text(note, style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
            ),
        ],
      ),
    );
  }

  Widget _formulaPanel(String title, String formula, String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            formula,
            style: TextStyle(color: primary, fontSize: 15, fontWeight: FontWeight.w700, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(note, style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _finalPanel(String title, List<(String, String)> lines, String total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WebTheme.brand,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                total,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in lines) ...[
            Text(line.$1, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(line.$2, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35)),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _monthlyHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WebTheme.brandSoftOf(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.analytics_outlined, color: primary, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONTHLY PERFORMANCE SCORE',
                  style: TextStyle(
                    fontSize: 11,
                    color: muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '100 points',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Maximum monthly score',
                  style: TextStyle(fontSize: 13, color: muted),
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
            color: WebTheme.brand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
              SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ],
          ),
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
            color: primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 9),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
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

          SizedBox(height: 15),

          Text(
            'The weightage changes depending on whether the staff member '
            'has tasks, goals, or both.',
            style: TextStyle(fontSize: 12, color: muted, height: 1.5),
          ),

          SizedBox(height: 18),

          // BOTH
          _weightCase(
            title: 'TASK + GOAL EXIST',
            task: '45',
            goal: '40',
            attitude: '15',
            total: '100',
          ),

          SizedBox(height: 10),

          // TASK ONLY
          _weightCase(
            title: 'ONLY TASK EXISTS',
            task: '85',
            goal: '0',
            attitude: '15',
            total: '100',
            highlighted: true,
          ),

          SizedBox(height: 10),

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
      padding: EdgeInsets.all(14),
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
            style: TextStyle(
              fontSize: 10,
              color: muted,
              fontWeight: FontWeight.bold,
              letterSpacing: .8,
            ),
          ),

          SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _weightItem('TASK', task)),
              Expanded(child: _weightItem('GOAL', goal)),
              Expanded(child: _weightItem('ATTITUDE', attitude)),
              Expanded(child: _weightItem('TOTAL', total)),
            ],
          ),

          if (highlighted) ...[
            SizedBox(height: 12),
            Text(
              'The available Task/Goal component receives the full 85 points.',
              style: TextStyle(fontSize: 11, color: muted),
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
        Text(title, style: TextStyle(fontSize: 9, color: muted)),
        SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ink,
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

          SizedBox(height: 15),

          _formulaBox(
            'Task 1 + Task 2 + Task 3 + ...',
            'Total Tasks in Month',
            'Monthly Task Average',
          ),

          SizedBox(height: 14),

          _info(
            'Each task starts from its time score and priority score. When the task has a target quantity, that score is then reduced by the completed quantity.',
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

          SizedBox(height: 14),

          _scoreRow('High Priority', '+5'),

          _scoreRow('Medium Priority', '+3'),

          _scoreRow('Normal Priority', '+0'),

          SizedBox(height: 8),

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

          SizedBox(height: 14),

          _scoreRow('Before due date', '90'),
          _scoreRow('On due date', '85'),
          _scoreRow('1 day late', '80'),
          _scoreRow('2 days late', '75'),
          _scoreRow('3 days late', '70'),
          _scoreRow('4 days late', '65'),
          _scoreRow('5 days late', '60'),
          _scoreRow('6 days late', '55'),
          _scoreRow('7 or more days late', '50'),

          SizedBox(height: 7),

          _info(
            'A task with an end time uses hours instead of days: 90 before the end time, 85 at the end time, then minus 5 for each late hour. The time score stays between 50 and 90.',
          ),
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

          SizedBox(height: 14),

          _scoreRow('High Priority task removed', '-10'),
          _scoreRow('Medium Priority task removed', '-5'),
          _scoreRow('Normal Priority task removed', '-3'),

          SizedBox(height: 8),

          _info(
            'Removal penalties are deducted from the monthly task average.',
          ),
        ],
      ),
    );
  }

  Widget _taskQuantity() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('TASK QUANTITY SCORE'),

          SizedBox(height: 14),

          _scoreRow('No target quantity', 'Time + Priority'),
          _scoreRow('Completed quantity missing', '0'),
          _scoreRow('Completed at or above target', 'Full task score'),
          _scoreRow('Completed below target', 'Task score × completed ÷ target'),

          SizedBox(height: 14),

          _formulaBox(
            'Task score × Completed quantity',
            'Target quantity',
            'Quantity score',
          ),

          SizedBox(height: 14),

          _info(
            'Example: task score 90, target 10, completed 6. The score is 90 × 6 ÷ 10 = 54. The result is rounded and stays between 0 and 90.',
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

          SizedBox(height: 15),

          _formulaBox(
            'Task 1 + Task 2 + Task 3 + ...',
            'Total Tasks in Goal',
            'Goal Task Average',
          ),

          SizedBox(height: 16),

          _formulaResult(
            'Goal Task Average + Priority + Time Score',
            'GOAL POINTS',
          ),

          SizedBox(height: 12),

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

          SizedBox(height: 14),

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

          SizedBox(height: 14),

          _scoreRow('Before due date', '+5'),
          _scoreRow('On due date', '+5'),
          _scoreRow('1 day late', '-5'),
          _scoreRow('2 days late', '-10'),
          _scoreRow('3 days late', '-15'),

          SizedBox(height: 7),

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

          SizedBox(height: 15),

          _formulaBox(
            'Staff Attitude & Behaviour Scores',
            'Number of Staff Scores',
            'Average Attitude & Behaviour',
          ),

          SizedBox(height: 15),

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

          SizedBox(height: 18),

          // BOTH
          _finalFormula(
            'If Task + Goal exist',
            'Task: (Monthly Task Score ÷ 100) × 45',
            'Goal: (Monthly Goal Score ÷ 100) × 40',
          ),

          SizedBox(height: 12),

          // TASK ONLY
          _finalFormula(
            'If ONLY Task exists',
            'Task: (Monthly Task Score ÷ 100) × 85',
            'Goal: 0',
            highlighted: true,
          ),

          SizedBox(height: 12),

          // GOAL ONLY
          _finalFormula(
            'If ONLY Goal exists',
            'Task: 0',
            'Goal: (Monthly Goal Score ÷ 100) × 85',
            highlighted: true,
          ),

          SizedBox(height: 18),

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

          SizedBox(height: 16),

          _weightLine('Department Task', '40'),
          _weightLine('Department Goal', '35'),
          _weightLine('Attitude & Behaviour', '15'),
          _weightLine('Department 5S', '10'),

          Divider(color: border, height: 25),

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

          SizedBox(height: 15),

          _formulaBox(
            'All Staff Monthly Task Points',
            'Number of Staff',
            'Average Staff Task Points',
          ),

          SizedBox(height: 16),

          _formulaResult(
            '(Average Staff Task Points ÷ 45) × 40',
            'DEPARTMENT TASK',
          ),

          SizedBox(height: 12),

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

          SizedBox(height: 15),

          _formulaBox(
            'All Staff Monthly Goal Points',
            'Number of Staff',
            'Average Staff Goal Points',
          ),

          SizedBox(height: 16),

          _formulaResult(
            '(Average Staff Goal Points ÷ 40) × 35',
            'DEPARTMENT GOAL',
          ),

          SizedBox(height: 12),

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

          SizedBox(height: 15),

          _formulaBox(
            'All Staff Attitude & Behaviour Scores',
            'Number of Staff',
            'Average Attitude & Behaviour',
          ),

          SizedBox(height: 14),

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

          SizedBox(height: 15),

          _formulaBox(
            'W1 + W2 + W3 + ...',
            'Number of 5S Assessments',
            'Average 5S Score',
          ),

          SizedBox(height: 16),

          _formulaResult('(Average 5S Score ÷ 100) × 10', 'DEPARTMENT 5S'),

          SizedBox(height: 12),

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

          SizedBox(height: 18),

          _weightLine('Department Task', '40'),
          _weightLine('Department Goal', '35'),
          _weightLine('Attitude & Behaviour', '15'),
          _weightLine('Department 5S', '10'),

          SizedBox(height: 15),

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
      padding: EdgeInsets.all(18),
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
      style: TextStyle(
        fontSize: 10,
        color: muted,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _formulaBox(String numerator, String denominator, String result) {
    return Column(
      children: [
        _formulaPart(numerator),

        SizedBox(height: 4),

        Text('÷', style: TextStyle(fontSize: 18, color: muted)),

        SizedBox(height: 4),

        _formulaPart(denominator, dark: true),

        SizedBox(height: 8),

        Icon(Icons.arrow_downward, size: 17, color: muted),

        SizedBox(height: 7),

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primary.withOpacity(.45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            result,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _formulaPart(String text, {bool dark = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withOpacity(.10) : cardLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _scoreRow(String title, String score) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: muted),
          SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 13, color: muted),
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primary.withOpacity(.40),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              score,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: WebTheme.isDark(context) ? const Color(0xFF052E16) : Colors.white,
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
      padding: EdgeInsets.all(14),
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
            style: TextStyle(
              fontSize: 12,
              color: muted,
              height: 1.4,
            ),
          ),

          SizedBox(height: 8),

          Icon(Icons.arrow_downward, size: 16, color: muted),

          SizedBox(height: 5),

          Text(
            result,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ink,
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
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary.withOpacity(.40),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(title),

          SizedBox(height: 12),

          Text(
            formula,
            style: TextStyle(
              color: ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),

          SizedBox(height: 12),

          Text(
            result,
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _info(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: muted,
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
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primary.withOpacity(.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: muted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ink,
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
      padding: EdgeInsets.all(14),
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
            style: TextStyle(
              fontSize: 10,
              color: muted,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 10),

          Text(
            line1,
            style: TextStyle(fontSize: 12, color: muted),
          ),

          SizedBox(height: 5),

          Text(
            line2,
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _calculationBox(String title, String formula, String result) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: WebTheme.brand,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          SizedBox(height: 9),

          Text(
            formula,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              height: 1.5,
            ),
          ),

          SizedBox(height: 10),

          Divider(color: border),

          SizedBox(height: 8),

          Text(
            result,
            style: TextStyle(
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
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: muted,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '$points points',
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

}
