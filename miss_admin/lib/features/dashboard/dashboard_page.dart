// lib/features/dashboard/dashboard_page.dart - 数据看板页面
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '数据看板',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '更新于: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 统计卡片
            Row(
              children: [
                Expanded(child: _StatCard(
                  title: '总用户数',
                  value: '12,345',
                  change: '+12.5%',
                  icon: Icons.people,
                  color: Colors.blue,
                )),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(
                  title: '活跃用户',
                  value: '8,234',
                  change: '+8.2%',
                  icon: Icons.trending_up,
                  color: Colors.green,
                )),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(
                  title: '今日新增',
                  value: '156',
                  change: '+23.1%',
                  icon: Icons.person_add,
                  color: Colors.orange,
                )),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(
                  title: 'VIP用户',
                  value: '567',
                  change: '+5.3%',
                  icon: Icons.star,
                  color: Colors.purple,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // 图表区域
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户增长趋势图
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '用户增长趋势',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _UserGrowthChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 注册方式分布
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '注册方式分布',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _RegistrationPieChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 最近活动
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最近活动',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _RecentActivityTable(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserGrowthChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
                if (value >= 0 && value < days.length) {
                  return Text(days[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 100),
              FlSpot(1, 150),
              FlSpot(2, 180),
              FlSpot(3, 220),
              FlSpot(4, 280),
              FlSpot(5, 320),
              FlSpot(6, 350),
            ],
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationPieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.blue,
            value: 40,
            title: '手机号',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          PieChartSectionData(
            color: Colors.green,
            value: 30,
            title: '邮箱',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          PieChartSectionData(
            color: Colors.orange,
            value: 15,
            title: '微信',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          PieChartSectionData(
            color: Colors.grey,
            value: 15,
            title: '其他',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          children: const [
            _TableHeader('用户'),
            _TableHeader('操作'),
            _TableHeader('方式'),
            _TableHeader('时间'),
            _TableHeader('状态'),
          ],
        ),
        ...List.generate(5, (index) => TableRow(
          children: [
            _TableCell('user_$index@example.com'),
            _TableCell('登录应用'),
            _TableCell('邮箱'),
            _TableCell('2分钟前'),
            _TableCell('成功'),
          ],
        )),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
