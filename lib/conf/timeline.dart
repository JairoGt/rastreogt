import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timelines/timelines.dart';

const completeColor = Color.fromARGB(255, 158, 134, 134);
const inProgressColor = Color(0xff5ec792);
const todoColor = Color(0xffd1d2d7);

class TimelineWidget extends StatefulWidget {
  final List<String> processes;
  final int processIndex;

  const TimelineWidget({super.key, required this.processes, required this.processIndex});

  @override
  _TimelineWidgetState createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  Color getColor(int index) {
    if (index == widget.processIndex) {
      return inProgressColor;
    } else if (index < widget.processIndex) {
      return completeColor;
    } else {
      return todoColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.0, // Ajusta la altura según tus necesidades
      child: Timeline.tileBuilder(
        theme: TimelineThemeData(
          direction: Axis.horizontal,
          connectorTheme: const ConnectorThemeData(
            space: 30.0,
            thickness: 5.0,
          ),
        ),
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          itemExtentBuilder: (_, __) =>
              MediaQuery.of(context).size.width / widget.processes.length,
          oppositeContentsBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Image.asset(
                'assets/images/status${index + 1}.png',
                width: 50.0,
                color: getColor(index),
              ),
            );
          },
          contentsBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Text(
                widget.processes[index],
                style: GoogleFonts.roboto(
                  fontSize: 18.0,
                  color: getColor(index),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
          indicatorBuilder: (_, index) {
            Color color;
            if (index == widget.processIndex) {
              color = inProgressColor;
            } else if (index < widget.processIndex) {
              color = completeColor;
            } else {
              color = todoColor;
            }

            if (index <= widget.processIndex) {
              return Stack(
                children: [
                  const CustomPaint(
                    size: Size(30.0, 30.0),
                  ),
                  DotIndicator(
                    size: 30.0,
                    color: color,
                   
                  ),
                ],
              );
            } else {
              return Stack(
                children: [
                  const CustomPaint(
                    size: Size(15.0, 15.0),
                  ),
                  OutlinedDotIndicator(
                    borderWidth: 4.0,
                    color: color,
                  ),
                ],
              );
            }
          },
          connectorBuilder: (_, index, type) {
            if (index > 0) {
              if (index == widget.processIndex) {
                final prevColor = getColor(index - 1);
                final color = getColor(index);
                List<Color> gradientColors;
                if (type == ConnectorType.start) {
                  gradientColors = [
                    Color.lerp(prevColor, color, 0.5)!,
                    color
                  ];
                } else {
                  gradientColors = [
                    prevColor,
                    Color.lerp(prevColor, color, 0.5)!
                  ];
                }
                return DecoratedLineConnector(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                    ),
                  ),
                );
              } else {
                return SolidLineConnector(
                  color: getColor(index),
                );
              }
            } else {
              return null;
            }
          },
          itemCount: widget.processes.length,
        ),
      ),
    );
  }
}