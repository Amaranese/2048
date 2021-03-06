import 'dart:math';

import 'package:twopowereleven/config/ui.dart';
import 'package:twopowereleven/widgets/game/board.dart';
import 'package:twopowereleven/widgets/game/material/control.dart';
import 'package:twopowereleven/widgets/game/material/score.dart';
import 'package:twopowereleven/widgets/game/material/sheets.dart';
import 'package:twopowereleven/widgets/game/material/steps.dart';
import 'package:twopowereleven/widgets/game/material/stopwatch.dart';
import 'package:twopowereleven/widgets/game/presenter/main.dart';
import 'package:twopowereleven/widgets/icons/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class GameMaterialPage extends StatelessWidget {
  /// Maximum size of the board,
  /// in pixels.
  static const kMaxBoardSize = 400.0;

  static const kBoardMargin = 16.0;

  static const kBoardPadding = 4.0;

  final FocusNode _boardFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    final presenter = GamePresenterWidget.of(context);

    final screenSize = MediaQuery.of(context).size;
    final screenWidth =
        MediaQuery.of(context).orientation == Orientation.portrait
            ? screenSize.width
            : screenSize.height;
    final screenHeight =
        MediaQuery.of(context).orientation == Orientation.portrait
            ? screenSize.height
            : screenSize.width;

    final isTallScreen = screenHeight > 800 || screenHeight / screenWidth > 1.9;
    final isLargeScreen = screenWidth > 400;

    final fabWidget = _buildFab(context);
    final boardWidget = _buildBoard(context);
    return OrientationBuilder(builder: (context, orientation) {
      final statusWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GameScoreWidget(
                score: presenter.score,
              ),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GameStepsWidget(
                    steps: presenter.steps,
                  ),
                  GameStopwatchWidget(
                    time: presenter.time,
                    fontSize: 14.0,
                  ),
                ],
              )
            ],
          ),
        ],
      );

      if (orientation == Orientation.portrait) {
        //
        // Portrait layout
        //
        return Scaffold(
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                isTallScreen
                    ? Container(
                        height: 56,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const AppIcon(size: 24.0),
                              const SizedBox(width: 16.0),
                              Text(
                                'Game of 2048',
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(height: 0),
                const SizedBox(height: 32.0),
                Center(
                  child: statusWidget,
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: boardWidget,
                  ),
                ),
                isLargeScreen && isTallScreen
                    ? const SizedBox(height: 116.0)
                    : const SizedBox(height: 72.0),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: fabWidget,
        );
      } else {
        //
        // Landscape layout
        //
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: boardWidget,
                  flex: 3,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      statusWidget,
                      SizedBox(height: 48.0),
                      fabWidget,
                    ],
                  ),
                  flex: 2,
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  Widget _buildBoard(final BuildContext context) {
    final presenter = GamePresenterWidget.of(context);
    final config = ConfigUiContainer.of(context);
    final background = Theme.of(context).brightness == Brightness.dark
        ? Colors.black54
        : Colors.black12;
    return Center(
      child: Container(
        margin: EdgeInsets.all(kBoardMargin),
        padding: EdgeInsets.all(kBoardPadding),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final puzzleSize = min(
              min(
                constraints.maxWidth,
                constraints.maxHeight,
              ),
              kMaxBoardSize - (kBoardMargin + kBoardPadding) * 2,
            );

            return RawKeyboardListener(
              autofocus: true,
              focusNode: _boardFocus,
              onKey: (event) {
                if (!(event is RawKeyDownEvent)) {
                  return;
                }

                int offsetY = 0;
                int offsetX = 0;
                switch (event.logicalKey.keyId) {
                  case 0x100070052: // arrow up
                    offsetY = -1;
                    break;
                  case 0x100070050: // arrow left
                    offsetX = -1;
                    break;
                  case 0x10007004f: // arrow right
                    offsetX = 1;
                    break;
                  case 0x100070051: // arrow down
                    offsetY = 1;
                    break;
                  default:
                    return;
                }
                final point = Point(offsetX, offsetY);
                presenter.swipe(point: point);
              },
              child: BoardWidget(
                isSpeedRunModeEnabled: config.isSpeedRunModeEnabled,
                board: presenter.board,
                size: puzzleSize,
                onSwipe: (point) {
                  presenter.swipe(point: point);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFab(final BuildContext context) {
    final presenter = GamePresenterWidget.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(width: 48.0, height: 48.0),
        const SizedBox(width: 16.0),
        GamePlayStopButton(
          isPlaying: presenter.isPlaying(),
          onTap: () {
            presenter.playStop();
          },
        ),
        const SizedBox(width: 16.0),
        Container(
          width: 48,
          height: 48,
          child: Material(
            elevation: 0.0,
            color: Colors.transparent,
            shape: CircleBorder(),
            child: InkWell(
              onTap: () {
                // Show the modal bottom sheet on
                // tap on "More" icon.
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return createMoreBottomSheet(context, call: (size) {
                      presenter.resize(size);
                    });
                  },
                );
              },
              customBorder: CircleBorder(),
              child: Icon(Icons.more_vert),
            ),
          ),
        ),
      ],
    );
  }
}
