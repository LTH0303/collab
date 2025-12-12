import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ⚠️ 注意：请根据你的实际文件夹结构调整 import 路径
import '../../ViewModel/JobViewModule/job_view_model.dart';
import '../../models/project_model.dart';

class ParticipantJobBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 获取 ViewModel
    final viewModel = Provider.of<JobViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50], // 浅灰背景，突出卡片
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Village Opportunities", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text("Find tasks, earn rewards", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.filter_list), onPressed: () {}),
          SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<List<Project>>(
        stream: viewModel.activeProjectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading jobs: ${snapshot.error}"));
          }

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No active projects found."),
                  Text("Check back later!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return _buildProjectCard(context, projects[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 头部：渐变背景 + 标题
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.shade700, Colors.teal.shade600]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text("Active Recruitment", style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                    Icon(Icons.bookmark_border, color: Colors.white),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  project.title,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 2. 内容区域
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 信息行：时间 & 人数
                Row(
                  children: [
                    _iconText(Icons.access_time, project.timeline),
                    SizedBox(width: 20),
                    _iconText(Icons.people_outline, project.participantRange),
                  ],
                ),
                SizedBox(height: 15),

                // 技能标签
                Text("Skills Needed", style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  children: project.skills.map((s) => Chip(
                    label: Text(s, style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.grey[100],
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),

                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 10),

                // --- 3. 核心修改：里程碑奖励 (垂直时间轴样式) ---
                Text("Milestones & Incentives", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Complete tasks to unlock rewards", style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 15),

                // 遍历显示里程碑
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: project.milestones.length,
                  itemBuilder: (context, index) {
                    final m = project.milestones[index];
                    final isLast = index == project.milestones.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 左侧：时间轴线
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 6,
                                backgroundColor: Colors.teal, // 绿色圆点
                              ),
                              if (!isLast)
                                Expanded(child: Container(width: 2, color: Colors.grey[200])),
                            ],
                          ),
                          SizedBox(width: 15),

                          // 右侧：任务详情
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${m.phaseName}: ${m.taskName}",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  SizedBox(height: 4),

                                  // 奖励 (Incentive) - 突出显示
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.orange.withOpacity(0.3))
                                    ),
                                    child: Text(
                                      "🎁 Reward: ${m.incentive}",
                                      style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),

                                  // 验证方式 (Verification Type)
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                          m.verificationType == 'photo' ? Icons.camera_alt : Icons.verified_user,
                                          size: 12, color: Colors.grey
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        m.verificationType == 'photo' ? "Requires Photo Proof" : "Verified by Leader",
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 10),
                // 申请按钮
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Application Submitted for ${project.title}!"))
                      );
                    },
                    child: Text("Apply for Project", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 5),
        Text(text, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
      ],
    );
  }
}