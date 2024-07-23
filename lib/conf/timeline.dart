import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timelines/timelines.dart';

const inProgressColor = Color(0xff5ec792);

class TimelineWidget extends StatefulWidget {
  final List<String> processes;
  final int processIndex;

  const TimelineWidget({super.key, required this.processes, required this.processIndex});

  @override
  _TimelineWidgetState createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  
  Color getColor(BuildContext context, int index) {
    // Obtener el tema actual
    final brightness = Theme.of(context).brightness;

    // Definir colores para tema claro y oscuro
    final completeColor = brightness == Brightness.dark
        ? Color.fromARGB(255, 136, 132, 132) // Color para tema oscuro
        : Color.fromARGB(255, 200, 167, 167); // Color para tema claro

    final todoColor = brightness == Brightness.dark
        ? Color(0xffd1d2d7) // Color para tema oscuro
        : Color.fromARGB(255, 66, 69, 84); // Color para tema claro (puedes cambiarlo si es necesario)

    // Devolver el color adecuado según el índice
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
                color: getColor(context, index),
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
                  color: getColor(context, index),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
          indicatorBuilder: (context, index) {
            Color color;
            var child;
            if (index == widget.processIndex) {
              color = inProgressColor;
              child = const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              );
            } else if (index < widget.processIndex) {
              color = getColor(context, index);
              child = Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.onSurface,
                size: 15.0,
              );
            } else {
              color = getColor(context, index);
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
                    child: child,
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
          connectorBuilder: (context, index, type) {
            if (index > 0) {
              if (index == widget.processIndex) {
                final prevColor = getColor(context, index - 1);
                final color = getColor(context, index);
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
                  color: getColor(context, index),
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