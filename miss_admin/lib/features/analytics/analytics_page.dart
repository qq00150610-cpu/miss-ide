// lib/features/analytics/analytics_page.dart - 数据分析页面
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据分析',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // 筛选条件
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('时间范围: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: '最近30天',
                      items: const [
                        DropdownMenuItem(value: '最近7天', child: Text('最近7天')),
                        DropdownMenuItem(value: '最近30天', child: Text('最近30天')),
                        DropdownMenuItem(value: '最近90天', child: Text('最近90天')),
                        DropdownMenuItem(value: '最近一年', child: Text('最近一年')),
                      ],
                      onChanged: (value) {},
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('导出报告'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 用户增长趋势
            Row(
              children: [
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
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '活跃用户统计',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _ActiveUsersChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 地区分布
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '用户地区分布',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: Row(
                        children: [
                          Expanded(
                            child: _RegionBarChart(),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _RegionLegend(color: Colors.blue, name: '北京', percent: '25%'),
                                _RegionLegend(color: Colors.green, name: '上海', percent: '20%'),
                                _RegionLegend(color: Colors.orange, name: '广东', percent: '18%'),
                                _RegionLegend(color: Colors.purple, name: '浙江', percent: '15%'),
                                _RegionLegend(color: Colors.red, name: '其他', percent: '22%'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 详细数据表格
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '详细数据',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('日期')),
                        DataColumn(label: Text('新增用户')),
                        DataColumn(label: Text('活跃用户')),
                        DataColumn(label: Text('登录次数')),
                        DataColumn(label: Text('平均在线时长')),
                      ],
                      rows: List.generate(7, (index) {
                        final date = DateTime.now().subtract(Duration(days: index));
                        return DataRow(cells: [
                          DataCell(Text('${date.month}-${date.day}')),
                          DataCell(Text('${150 + index * 10}')),
                          DataCell(Text('${800 + index * 50}')),
                          DataCell(Text('${2000 + index * 100}')),
                          DataCell(Text('${30 + index}分钟')),
                        ]);
                      }),
                    ),
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

class _UserGrowthChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 500,
        barGroups: List.generate(7, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: 150 + (index * 30).toDouble(),
                color: Theme.of(context).primaryColor,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
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
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
      ),
    );
  }
}

class _ActiveUsersChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: 45,
            title: 'DAU\n45%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          PieChartSectionData(
            color: Colors.blue,
            value: 30,
            title: 'WAU\n30%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          PieChartSectionData(
            color: Colors.purple,
            value: 25,
            title: 'MAU\n25%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _RegionBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: 80, color: Colors.blue, width: 30)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: 65, color: Colors.green, width: 30)],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: 55, color: Colors.orange, width: 30)],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [BarChartRodData(toY: 45, color: Colors.purple, width: 30)],
          ),
          BarChartGroupData(
            x: 4,
            barRods: [BarChartRodData(toY: 35, color: Colors.red, width: 30)],
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const regions = ['北京', '上海', '广东', '浙江', '其他'];
                if (value >= 0 && value < regions.length) {
                  return Text(regions[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
      ),
    );
  }
}

class _RegionLegend extends StatelessWidget {
  final Color color;
  final String name;
  final String percent;

  const _RegionLegend({
    required this.color,
    required this.name,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(name),
          const Spacer(),
          Text(percent, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
