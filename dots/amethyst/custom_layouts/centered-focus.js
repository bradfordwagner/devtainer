
function layout() {
    return {
        name: "Centered Focus",
        initialState: {
            xRatio: 0.75,
            yRatio: 0.85,
            ratioDelta: 0.01,
            gapRatio: 0.05,     // placeholder space for focused window
            lastFocusedID: "",  // window id which was last focused
        },
        commands: {
            command1: {
                description: "Decrease Y",
                updateState: (state) => {
                    return { ...state, yRatio: Math.max(0, state.yRatio - state.ratioDelta) };
                }
            },
            command2: {
                description: "Increase Y",
                updateState: (state) => {
                    return { ...state, yRatio: Math.min(1, state.yRatio + state.ratioDelta) };
                    // return { ...state, xRatio: Math.min(1, state.xRatio + state.ratioDelta), yRatio: Math.min(1, state.yRatio + state.ratioDelta) };
                }
            },
            command3: {
                description: "Decrease X",
                updateState: (state) => {
                    return { ...state, xRatio: Math.max(0, state.xRatio - state.ratioDelta) };
                    // return { ...state, xRatio: Math.max(0, state.xRatio - state.ratioDelta), yRatio: Math.max(0, state.yRatio - state.ratioDelta) };
                }
            },
            command4: {
                description: "Increase X",
                updateState: (state) => {
                    return { ...state, xRatio: Math.min(1, state.xRatio + state.ratioDelta) };
                    // return { ...state, xRatio: Math.min(1, state.xRatio + state.ratioDelta), yRatio: Math.min(1, state.yRatio + state.ratioDelta) };
                }
            },
        },
        getFrameAssignments: (windows, screenFrame, state) => {
            let currentY = screenFrame.y;
            const yFocusedGap = state.gapRatio * screenFrame.height;

            let numNativeFocused = 0;
            let numlastFocused = 0;
            windows.forEach(w => {
                if (w.isFocused) {
                    numNativeFocused++;
                } else if (w.id == state.lastFocusedID) {
                    numlastFocused++;
                }
            })
            const hasNativeFocus = numNativeFocused > 0;
            const clamp = (num, min, max) => Math.min(Math.max(num, min), max);

            const numWindows = windows.length;
            const numFocused = clamp(numNativeFocused + numlastFocused, 0, 1);
            const numSecondaryWindows = numWindows - numFocused;
            const secondaryPaneWindowHeight = numSecondaryWindows > 0
                ? (screenFrame.height - yFocusedGap) / numSecondaryWindows
                : (screenFrame.height - yFocusedGap) / Math.max(1, numWindows);

            return windows.reduce((frames, window, index) => {
                let frame;
                if ((hasNativeFocus && window.isFocused) || (!hasNativeFocus && window.id == state.lastFocusedID)) {
                    const xInset = screenFrame.width  * (1 - state.xRatio)/2
                    const yInset = screenFrame.height * (1 - state.yRatio)/2
                    frame = {
                        x: screenFrame.x + xInset,
                        y: screenFrame.y + yInset,
                        width: screenFrame.width * state.xRatio,
                        height: screenFrame.height * state.yRatio,
                    };
                    currentY += yFocusedGap;
                } else {
                    frame = {
                        x: screenFrame.x,
                        y: currentY,
                        width: screenFrame.width,
                        height: secondaryPaneWindowHeight,
                    }
                    currentY += secondaryPaneWindowHeight;
                }
                return { ...frames, [window.id]: frame };
            }, {});
        },
        updateWithChange: (change, state) => {
            switch (change.change) {
                case "focus_changed":
                    state.lastFocusedID = change.windowID;
                    break;
            }
            return state;
        }
    };
}
