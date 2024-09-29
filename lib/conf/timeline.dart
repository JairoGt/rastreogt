import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timelines/timelines.dart';
import 'package:lottie/lottie.dart';

const inProgressColor = Color(0xff5ec792);

class TimelineWidget extends StatefulWidget {
  final List<String> processes;
  final int processIndex;

  const TimelineWidget(
      {super.key, required this.processes, required this.processIndex});

  @override
  _TimelineWidgetState createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.processes.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      ),
    );

    // Inicia la animación del índice actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.processIndex < _controllers.length) {
        _controllers[widget.processIndex].reset();
        _controllers[widget.processIndex].forward();
      }
    });
  }

  @override
  void didUpdateWidget(TimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.processIndex != widget.processIndex) {
      if (widget.processIndex < _controllers.length) {
        _controllers[widget.processIndex].reset();
        _controllers[widget.processIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Color getColor(BuildContext context, int index) {
    final brightness = Theme.of(context).brightness;

    final completeColor = brightness == Brightness.dark
        ? const Color.fromARGB(255, 136, 132, 132)
        : const Color.fromARGB(255, 125, 116, 116);

    final todoColor = brightness == Brightness.dark
        ? const Color(0xffd1d2d7)
        : const Color.fromARGB(255, 66, 69, 84);

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
    if (_controllers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color.fromARGB(
                115, 9, 9, 22) // Azul oscuro para modo oscuro
            : const Color.fromARGB(
                148, 109, 58, 131), // Color actual para modo claro
        borderRadius: BorderRadius.circular(10.0), // Bordes redondeados
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(66, 99, 62, 89), // Sombra
            blurRadius: 10.0, // Desenfoque de la sombra
            offset: Offset(0, 5), // Desplazamiento de la sombra
          ),
        ],
      ),
      padding: const EdgeInsets.all(8.0), // Espacio interno
      child: SizedBox(
        height: 190.0,
        child: Timeline.tileBuilder(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.all(1.0),
          theme: TimelineThemeData(
            direction: Axis.horizontal,
            connectorTheme: const ConnectorThemeData(
              space: 50.0,
              thickness: 5.0,
            ),
          ),
          builder: TimelineTileBuilder.connected(
            connectionDirection: ConnectionDirection.before,
            itemExtentBuilder: (_, __) =>
                MediaQuery.of(context).size.width / 4.4,
            oppositeContentsBuilder: (context, index) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 1.0),
                  child: index == widget.processIndex
                      ? Lottie.asset(
                          'assets/lotties/status${index + 1}.json',
                          controller: _controllers[index],
                          width: 72.0,
                          fit: BoxFit.cover,
                          onLoaded: (composition) {
                            _controllers[index].duration = composition.duration;
                            if (index == widget.processIndex) {
                              _controllers[index].reset();
                              _controllers[index].forward();
                            }
                          },
                        )
                      : Lottie.asset(
                          'assets/lotties/status${index + 1}.json',
                          width: 72.0,
                          frameBuilder: (context, child, composition) {
                            if (composition == null) {
                              return const SizedBox
                                  .shrink(); // or some other placeholder
                            }

                            final durationInMilliseconds =
                                composition.duration.inMilliseconds;

                            // Especifica el frame como un porcentaje de la duración total
                            final specificTime = durationInMilliseconds * 1;

                            _controllers[index].addListener(() {
                              if (_controllers[index].value *
                                      durationInMilliseconds >=
                                  specificTime) {
                                _controllers[index]
                                    .stop(); // Detiene la animación en el tiempo específico
                              }
                            });

                            return AnimatedOpacity(
                              opacity: index == widget.processIndex ? 1.0 : 0.5,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              child: child,
                            );
                          },
                          repeat: false,
                          frameRate: FrameRate.max,
                          fit: BoxFit.cover,
                        ),
                ),
              );
            },
            contentsBuilder: (context, index) {
              return Align(
                alignment: Alignment.centerLeft, // Alinea a la izquierda
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 1.0), // Ajusta el padding según tus necesidades
                  child: Text(
                    widget.processes[index],
                    style: GoogleFonts.roboto(
                      fontSize: 13.0,
                      color: getColor(context, index),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
            indicatorBuilder: (context, index) {
              Color color;
              Widget child;
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
                  size: 12.0,
                );
              } else {
                color = getColor(context, index);
              }

              if (index <= widget.processIndex) {
                return Stack(
                  children: [
                    const CustomPaint(
                      size: Size(25.0, 25.0),
                    ),
                    DotIndicator(
                      size: 25.0,
                      color: color,
                      // child: child,
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
      ),
    );
  }
}
