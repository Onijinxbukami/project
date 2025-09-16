import 'package:flutter/material.dart';

class ProgressStepper extends StatelessWidget {
  final List<String> steps;
  final List<IconData>? stepIcons;
  final int currentStep;
  final Color backgroundColor;
  final Color progressColor;
  final double height;

  const ProgressStepper({
    Key? key,
    required this.steps,
    required this.currentStep,
    this.stepIcons,
    this.backgroundColor = Colors.grey,
    this.progressColor = const Color(0xFF1D4ED8), // Màu xanh Apple
    this.height = 6.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double progress = (currentStep + 1) / steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thanh tiến trình
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Phần đã hoàn thành
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Các bước
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isActive = index == currentStep;
            final isCompleted = index < currentStep;
            final icon = stepIcons != null && index < stepIcons!.length
                ? stepIcons![index]
                : null; // Lấy icon tương ứng nếu có

            return Expanded(
              child: Column(
                children: [
                  // Vòng tròn bước + đường kết nối
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (index != 0)
                        Positioned(
                          left: -screenWidth * 0.05,
                          right: 0,
                          child: Container(
                            height: 2,
                            color:
                                isCompleted ? progressColor : backgroundColor,
                          ),
                        ),
                      GestureDetector(
                        onTap: isCompleted
                            ? () {
                                // Handle tap trên bước đã hoàn thành
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive
                              ? screenWidth * 0.1
                              : screenWidth * 0.09, // Tăng kích thước vòng tròn
                          height:
                              isActive ? screenWidth * 0.1 : screenWidth * 0.09,
                          decoration: BoxDecoration(
                            color: isActive
                                ? progressColor
                                : (isCompleted
                                    ? Colors.green
                                    : backgroundColor),
                            shape: BoxShape.circle,
                          ),
                          child: icon != null
                              ? Icon(icon,
                                  color: Colors.white,
                                  size: screenWidth * 0.06) // Tăng size icon
                              : (isCompleted
                                  ? Icon(Icons.check,
                                      color: Colors.white,
                                      size: screenWidth * 0.06)
                                  : null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Nhãn của bước
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      steps[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
