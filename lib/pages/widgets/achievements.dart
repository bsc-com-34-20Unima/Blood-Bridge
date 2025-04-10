import 'package:flutter/material.dart';

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final int requiredDonations;
  final Color color;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredDonations,
    required this.color,
  });
}

class Achievements extends StatelessWidget {
  final int donations; // Number of donations by the donor

  const Achievements({super.key, required this.donations});

  @override
  Widget build(BuildContext context) {
    // Define all standard achievements based on donation count
    final List<Achievement> allAchievements = [
      Achievement(
        title: 'First Time Donor',
        description: 'Completed your first blood donation',
        icon: Icons.favorite,
        requiredDonations: 1,
        color: Colors.red,
      ),
      Achievement(
        title: 'Regular Hero',
        description: 'Donated blood 3 times',
        icon: Icons.favorite_border,
        requiredDonations: 3,
        color: Colors.redAccent,
      ),
      Achievement(
        title: 'Silver Donor',
        description: 'Completed 5 blood donations',
        icon: Icons.local_hospital,
        requiredDonations: 5,
        color: Colors.grey,
      ),
      Achievement(
        title: 'Gold Donor',
        description: 'Completed 10 blood donations',
        icon: Icons.emoji_events,
        requiredDonations: 10,
        color: Colors.amber,
      ),
      Achievement(
        title: 'Platinum Donor',
        description: 'Completed 15 blood donations',
        icon: Icons.shield,
        requiredDonations: 15,
        color: Colors.blueGrey,
      ),
      Achievement(
        title: 'Diamond Donor',
        description: 'Completed 25 blood donations',
        icon: Icons.star,
        requiredDonations: 25,
        color: Colors.blue,
      ),
    ];

    // Determine overall achievement level
    String level;
    double overallProgress;
    Color progressColor;

    if (donations >= 25) {
      level = 'Diamond Donor';
      overallProgress = 1.0;
      progressColor = Colors.blue;
    } else if (donations >= 15) {
      level = 'Platinum Donor';
      overallProgress = donations / 25;
      progressColor = Colors.blueGrey;
    } else if (donations >= 10) {
      level = 'Gold Donor';
      overallProgress = donations / 25;
      progressColor = Colors.amber;
    } else if (donations >= 5) {
      level = 'Silver Donor';
      overallProgress = donations / 25;
      progressColor = Colors.grey;
    } else if (donations >= 3) {
      level = 'Regular Hero';
      overallProgress = donations / 25;
      progressColor = Colors.redAccent;
    } else if (donations >= 1) {
      level = 'First Time Donor';
      overallProgress = donations / 25;
      progressColor = Colors.red;
    } else {
      level = 'New User';
      overallProgress = 0;
      progressColor = Colors.grey;
    }

    // Calculate next achievement
    int nextMilestone = 25;
    for (var achievement in allAchievements) {
      if (donations < achievement.requiredDonations) {
        nextMilestone = achievement.requiredDonations;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Achievements'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with current status
              Container(
                width: double.infinity,
                color: Colors.red,
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '$donations Donations',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress to next achievement',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            donations >= 25 
                                ? 'All achievements unlocked!' 
                                : '$donations/$nextMilestone',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 8,
                        backgroundColor: Colors.red.shade800,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Achievement cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: allAchievements.length,
                    itemBuilder: (context, index) {
                      final achievement = allAchievements[index];
                      final bool unlocked = donations >= achievement.requiredDonations;
                      
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: unlocked 
                              ? BorderSide(color: achievement.color, width: 2) 
                              : BorderSide(color: Colors.transparent),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: unlocked 
                                      ? achievement.color.withOpacity(0.1) 
                                      : Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  achievement.icon,
                                  color: unlocked 
                                      ? achievement.color 
                                      : Colors.grey,
                                  size: 32,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                achievement.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: unlocked 
                                      ? Colors.black87 
                                      : Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),
                              Text(
                                achievement.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              if (!unlocked)
                                Text(
                                  'Unlock at ${achievement.requiredDonations} donations',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}