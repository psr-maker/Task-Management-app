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
                        _taskPenalty(),
                      ],
                    ),

                    SizedBox(height: 12),

                    _monthlyTaskScore(),

                    SizedBox(height: 25),

                    _subHeader('B. Goal Score'),

                    SizedBox(height: 10),

                    _goalCalculation(),

                    SizedBox(height: 25),

                    _subHeader('C. Attitude & Behaviour'),

                    SizedBox(height: 10),

                    _attitude(),

                    SizedBox(height: 25),

                    _subHeader('D. Warning Penalty'),

                    SizedBox(height: 10),

                    _warningPenalty(),

                    SizedBox(height: 25),

                    _subHeader('E. Final Staff Score'),

                    SizedBox(height: 10),

                    _staffFinal(),

                    SizedBox(height: 25),

                    _workedExample(),

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
          'Each person is scored for one month from reviewed tasks, completed goals, and attitude. Warnings are taken off the final score only.',
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
          _formulaPanel(
            'Monthly task average',
            'Average of final review points',
            'Uses reviews for this staff member in the selected month, and only tasks assigned to them. No reviews means the task score is 0.',
          ),
          _formulaPanel(
            'Removal penalty',
            'Sum of applied penalty points that month',
            'Taken off the monthly task average. The task score cannot go below 0.',
          ),
        ]),
        const SizedBox(height: 12),
        _formulaPanel(
          'Monthly task score',
          'Task average − removal penalty',
          'This score is then converted to task points. With both tasks and goals it is worth 45. With tasks only it is worth 85.',
        ),
        const SizedBox(height: 22),
        Text('Goal, attitude, and warnings', style: _webHeading()),
        const SizedBox(height: 10),
        _webSplit(wide, [
          _formulaPanel(
            'Monthly goal score',
            'Average of goal points',
            'Uses goals completed in that month. No completed goals means the goal score is 0. With both tasks and goals this is worth 40. With goals only it is worth 85.',
          ),
          _formulaPanel(
            'Attitude and behaviour',
            'Behaviour total for the month',
            'The score stays between 0 and 15. It is added after task and goal points.',
          ),
        ]),
        const SizedBox(height: 12),
        _ruleTable('Warning penalty, taken off the final score', const [
          ('Low', '−1'),
          ('Medium', '−2'),
          ('High', '−3'),
          ('Critical', '−5'),
        ], note: 'Only active warnings created in that month are counted. The penalties are added together.'),
        const SizedBox(height: 12),
        _finalPanel(
          'Final staff score',
          const [
            ('Task points', '(Monthly task score ÷ 100) × task weight'),
            ('Goal points', '(Monthly goal score ÷ 100) × goal weight'),
            ('Productivity', 'Task points + goal points, maximum 85'),
            ('Total', 'Productivity + attitude − warning penalty, maximum 100'),
          ],
          'Maximum 100',
        ),
        const SizedBox(height: 22),
        _workedExample(),
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

  Widget _workedExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subHeader('F. Worked example'),
        const SizedBox(height: 10),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('FOLLOW ONE PERSON FOR ONE MONTH'),
              const SizedBox(height: 12),
              _info(
                'The score uses only that month. A review, a completed goal, a removal, or a warning from another month is ignored.',
              ),
              const SizedBox(height: 14),
              _scoreRow('1. Average the task reviews', '70'),
              _scoreRow('2. Subtract the removal penalty', '60'),
              _scoreRow('3. Average the completed goal points', '80'),
              _scoreRow('4. Turn those scores into points', '27 + 32'),
              _scoreRow('5. Add attitude', '12'),
              _scoreRow('6. Subtract this month’s warnings', '−5'),
              const SizedBox(height: 4),
              _resultBox('Final score', '66 / 100'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('TASKS IN THE EXAMPLE'),
              const SizedBox(height: 12),
              _info(
                'Two tasks assigned to this person were reviewed this month. Their final review points are 80 and 60.',
              ),
              const SizedBox(height: 14),
              _formulaBox(
                '80 + 60',
                '2 reviews',
                'Average = 70',
              ),
              const SizedBox(height: 14),
              _info(
                'A task removal this month has 10 penalty points applied. 70 − 10 = 60. If the penalty were larger than 70, the task score would stop at 0. It does not go negative.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('GOALS IN THE EXAMPLE'),
              const SizedBox(height: 12),
              _info(
                'Two goals were completed this month, with saved goal points of 90 and 70. A goal that is still open, or was completed in another month, is not included.',
              ),
              const SizedBox(height: 14),
              _formulaBox(
                '90 + 70',
                '2 completed goals',
                'Average = 80',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('WHY THE WEIGHTS ARE 45 AND 40'),
              const SizedBox(height: 12),
              _info(
                'This person has both a task review and a completed goal, so the task score is worth 45 and the goal score is worth 40. Attitude is a separate 15. Together that is 100 before any warning.',
              ),
              const SizedBox(height: 14),
              _scoreRow('Task points: (60 ÷ 100) × 45', '27'),
              _scoreRow('Goal points: (80 ÷ 100) × 40', '32'),
              _scoreRow('Productivity: 27 + 32', '59 / 85'),
              const SizedBox(height: 8),
              _info(
                'If the same person had reviews but no completed goal, the task score would use 85 instead of 45: (60 ÷ 100) × 85 = 51. Goal points would be 0. If they had only goals, the goal score would use 85.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('ATTITUDE AND WARNINGS'),
              const SizedBox(height: 12),
              _info(
                'The behaviour total recorded for this month is 12. It is kept between 0 and 15, then added to productivity: 59 + 12 = 71.',
              ),
              const SizedBox(height: 14),
              _scoreRow('One medium warning', '−2'),
              _scoreRow('One high warning', '−3'),
              _scoreRow('Warning total', '−5'),
              const SizedBox(height: 8),
              _info(
                'Only active warnings created in this month are used. 71 − 5 = 66. The final score stays between 0 and 100. Warnings do not change the task points, goal points, or attitude. They are taken off at the end.',
              ),
            ],
          ),
        ),
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
            'Task and goal share 85 points. Attitude adds up to 15. '
            'If a person has only tasks or only goals, that part receives the full 85. '
            'With neither, productivity is 0.',
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
            'Final points of reviewed tasks',
            'Number of reviews in the month',
            'Monthly Task Average',
          ),

          SizedBox(height: 14),

          _info(
            'Only tasks assigned to this staff member are included, and only reviews from the selected month. No reviews means the task score is 0.',
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

          _formulaBox(
            'Applied penalty points',
            'Removals in the month',
            'Removal penalty',
          ),

          SizedBox(height: 14),

          _info(
            'Only removals with a penalty applied in that month are counted. The points are added together and taken off the task average. The task score cannot go below 0.',
          ),
        ],
      ),
    );
  }

  Widget _monthlyTaskScore() {
    return _highlight(
      title: 'MONTHLY TASK SCORE',

      formula: 'Monthly Task Average − Removal Penalty',

      result: 'The result stays at 0 or above, then becomes the task points.',
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
            'Goal points of completed goals',
            'Completed goals in the month',
            'Monthly Goal Score',
          ),

          SizedBox(height: 12),

          _info(
            'A goal counts when it is completed in the selected month. No completed goals means the goal score is 0.',
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

          _resultBox('Behaviour total for the month', '0 to 15'),

          SizedBox(height: 15),

          _info(
            'The attitude score for that month is added after task and goal points. It cannot go above 15.',
          ),
        ],
      ),
    );
  }

  Widget _warningPenalty() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('WARNING PENALTY'),

          SizedBox(height: 14),

          _scoreRow('Low', '−1'),
          _scoreRow('Medium', '−2'),
          _scoreRow('High', '−3'),
          _scoreRow('Critical', '−5'),

          SizedBox(height: 8),

          _info(
            'Only active warnings created in that month are counted. The penalties are added together and taken off the final score. They do not change the task, goal, or attitude points.',
          ),
        ],
      ),
    );
  }

  Widget _staffFinal() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('FINAL STAFF SCORE'),

          SizedBox(height: 18),

          _finalFormula(
            'If Task + Goal exist',
            'Task: (Monthly Task Score ÷ 100) × 45',
            'Goal: (Monthly Goal Score ÷ 100) × 40',
          ),

          SizedBox(height: 12),

          _finalFormula(
            'If ONLY Task exists',
            'Task: (Monthly Task Score ÷ 100) × 85',
            'Goal: 0',
            highlighted: true,
          ),

          SizedBox(height: 12),

          _finalFormula(
            'If ONLY Goal exists',
            'Task: 0',
            'Goal: (Monthly Goal Score ÷ 100) × 85',
            highlighted: true,
          ),

          SizedBox(height: 18),

          _calculationBox(
            'PRODUCTIVITY',
            'Task points + Goal points',
            'MAXIMUM = 85',
          ),

          SizedBox(height: 12),

          _calculationBox(
            'FINAL FORMULA',
            'Productivity + Attitude − Warning penalty',
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
