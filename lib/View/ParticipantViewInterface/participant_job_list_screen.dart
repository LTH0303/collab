import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/JobViewModule/job_view_model.dart';
import '../../models/project_model.dart';

class ParticipantJobBoard extends StatelessWidget {
  const ParticipantJobBoard({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取 ViewModel
    final viewModel = Provider.of<JobViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50], // 浅灰背景
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Village Opportunities", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text("Find tasks, earn rewards", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<List<Project>>(
        stream: viewModel.activeProjectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No active projects found.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 顶部区域 (蓝色背景) ===
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Active Recruitment", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.bookmark_border, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 12),
                // 标题 (自动换行，不会溢出)
                Text(
                  project.title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // 地址行 (强制截断)
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.address.isNotEmpty ? project.address : "Village Area",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis, // 超长显示省略号
                        maxLines: 1,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // === 内容区域 ===
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 关键修复点：时间与人数行
                // 使用 Flex 布局严格控制比例，防止任何一方溢出
                Row(
                  children: [
                    // 左侧：时间 (占用大部分空间)
                    Expanded(
                      flex: 7, // 权重7
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded( // 内部再加 Expanded 确保文字被截断
                            child: Text(
                              project.timeline,
                              style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 右侧：人数 (占用小部分空间)
                    Expanded(
                      flex: 3, // 权重3
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end, // 靠右对齐
                        children: [
                          Icon(Icons.people_outline, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Flexible( // 允许文字缩小
                            child: Text(
                              project.participantRange,
                              style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 技能标签
                const Text("Skills Needed", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: project.skills.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0))),
                    backgroundColor: const Color(0xFFE3F2FD),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  )).toList(),
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 底部信息
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${project.milestones.length} Milestones", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text(
                      "Earn Rewards",
                      style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 申请按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Application Submitted for ${project.title}!"))
                      );
                    },
                    child: const Text("Apply for Project", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}