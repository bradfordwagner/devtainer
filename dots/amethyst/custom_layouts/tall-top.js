
function layout() {
    return {
        name: "Tall Top",
        initialState: {
            mainPaneCount: 1,
            mainRatio: 0.65,
            ratioDelta: 0.05,
        },
        commands: {
            command1: {
                description: "Decrease main ratio",
                updateState: (state) => {
                    return { ...state, mainRatio: Math.max(0, state.mainRatio - state.ratioDelta) };
                }
            },
            command2: {
                description: "Increase main ratio",
                updateState: (state) => {
                    return { ...state, mainRatio: Math.min(1, state.mainRatio + state.ratioDelta) };
                }
            },
            command3: {
                description: "Decrease main pane count",
                updateState: (state) => {
                    return { ...state, mainPaneCount: Math.max(1, state.mainPaneCount - 1) };
                }
            },
            command4: {
                description: "Increase main pane count",
                updateState: (state) => {
                    return { ...state, mainPaneCount: state.mainPaneCount + 1 };
                }
            },
        },
        getFrameAssignments: (windows, screenFrame, state) => {
            const mainPaneCount = Math.min(state.mainPaneCount, windows.length);
            const secondaryPaneCount = windows.length - mainPaneCount;
            const hasSecondaryPane = secondaryPaneCount > 0;

            const mainRatio = hasSecondaryPane ? state.mainRatio : 1.0; // fullscreen if no secondary
            const mainPaneWindowHeight = Math.round(screenFrame.height / mainPaneCount * mainRatio);
            const secondaryPaneWindowHeight = screenFrame.height * (1 - mainRatio);
            const secondaryPaneWindowWidth = screenFrame.width / secondaryPaneCount;

            return windows.reduce((frames, window, index) => {
                const isMain = index < mainPaneCount;
                let frame;
                if (isMain) {
                    frame = {
                        x: screenFrame.x,
                        y: screenFrame.y + (mainPaneWindowHeight * index) + secondaryPaneWindowHeight,
                        width: screenFrame.width,
                        height: mainPaneWindowHeight,
                    };
                } else {
                    const secondaryIndex = index - mainPaneCount;
                    frame = {
                        x: screenFrame.x + (secondaryPaneWindowWidth * secondaryIndex),
                        y: screenFrame.y,
                        width: secondaryPaneWindowWidth,
                        height: secondaryPaneWindowHeight,
                    }
                }
                return { ...frames, [window.id]: frame };
            }, {});
        }
    };
}
