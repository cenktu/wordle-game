import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.14

ApplicationWindow {
    visible: true
    width: 800
    height: 900
    title: "Wordle Game"
    color: "#FFF5E1"

    // Bind to C++ GameLogic properties
    property var gridData: gameLogic.grid
    property int currentRow: gameLogic.currentRow
    property int currentCol: gameLogic.currentCol
    property string targetWord: gameLogic.targetWord

    // List to hold the status of each grid cell
    property var statusData: []
    // Use a dictionary for keyboard colors
    property var keyboardStatus: {

    }
    // Flag to prevent further input after game over
    property bool gameOverFlag: false

    Component.onCompleted: {
        resetGameData()
        resetKeyboardStatus()
        console.log("Target word:", targetWord)
    }

    // Function to reset game data
    function resetGameData() {
        statusData = []
        for (var i = 0; i < 6 * 5; i++) {
            statusData.push("")
        }
    }

    // Function to reset keyboard status using a dictionary
    function resetKeyboardStatus() {
        keyboardStatus = {}
        var keyboardLetters = "QWERTYUIOPASDFGHJKLZXCVBNM"
        for (var i = 0; i < keyboardLetters.length; i++) {
            // Set all keys to lightgray initially
            keyboardStatus[keyboardLetters[i]] = "lightgray"
        }
        // Trigger bindings by creating a new reference
        keyboardStatus = Object.assign({}, keyboardStatus)
    }

    function resetGameStatus() {
        gameStatus.text = ""
        gameStatus.visible = false
    }

    // Function to handle key input
    function handleKeyInput(key) {

        if (gameOverFlag) {
            return
            // Ignore further input if game is over
        }

        if (key === "Enter") {
            if (currentCol === 5) {
                console.log("Submitting guess:",
                            gridData.slice(currentRow * 5,
                                           currentRow * 5 + 5).join(""))
                gameLogic.submitGuess()
            } else if (currentCol < 5) {
                shortGuessPopup.open()
                return
            }
        } else if (key === "Backspace") {
            if (currentCol > 0) {
                gameLogic.removeLetter()
            }
        } else if (/^[A-Za-z]$/.test(key) && currentCol < 5) {
            gameLogic.addLetter(key.toUpperCase())
        }
    }

    // Function to get key color from the keyboardStatus dictionary
    function getKeyColor(letter) {
        var upperLetter = letter.toUpperCase()
        if (keyboardStatus.hasOwnProperty(upperLetter)) {
            return keyboardStatus[upperLetter]
        } else {
            return "lightgray"
        }
    }

    // Grid to display the game board
    Grid {
        id: gameGrid
        rows: 6
        columns: 5
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5
        anchors.topMargin: 30

        Repeater {
            model: 6 * 5
            Rectangle {
                width: 70
                height: 70
                color: {
                    switch (statusData[index]) {
                    case "correct":
                        return "green"
                    case "present":
                        return "yellow"
                    case "absent":
                        return "gray"
                    default:
                        return "lightgray"
                    }
                }
                border.color: "black"

                Text {
                    anchors.centerIn: parent
                    text: gridData[index]
                    font.pixelSize: 32
                }
            }
        }
    }

    Column {
        id: keyboard
        anchors.top: gameGrid.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5
        anchors.topMargin: 90

        // Create the rows of keys
        Row {
            spacing: 5
            Repeater {
                model: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
                Rectangle {
                    width: 60
                    height: 60
                    color: getKeyColor(modelData)
                    border.color: "black"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 24
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: handleKeyInput(modelData)
                    }
                }
            }
        }

        Row {
            spacing: 5
            Repeater {
                model: ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
                Rectangle {
                    width: 60
                    height: 60
                    color: getKeyColor(modelData)
                    border.color: "black"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 24
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: handleKeyInput(modelData)
                    }
                }
            }
        }

        Row {
            spacing: 5
            Repeater {
                model: ["Enter", "Z", "X", "C", "V", "B", "N", "M", "Backspace"]
                Rectangle {
                    width: (modelData === "Enter"
                            || modelData === "Backspace") ? 120 : 60
                    height: 60
                    color: getKeyColor(modelData)
                    border.color: "black"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 24
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modelData === "Enter") {
                                handleKeyInput("Enter")
                            } else if (modelData === "Backspace") {
                                handleKeyInput("Backspace")
                            } else {
                                handleKeyInput(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // Custom Pop-Up Overlay for invalid guess
    Popup {
        id: invalidGuessPopup
        modal: true
        focus: true
        width: 250
        height: 150
        z: 10
        anchors.centerIn: parent

        Rectangle {
            anchors.fill: parent
            color: "#FFE6E6"
            radius: 10
            border.color: "#FF4C4C"
            border.width: 2

            // Use a FocusScope to handle key events inside the Popup
            FocusScope {
                anchors.fill: parent
                focus: true

                Column {
                    anchors.centerIn: parent
                    spacing: 20

                    Text {
                        text: "Not a valid word."
                        font.pixelSize: 16
                        wrapMode: Text.Wrap
                    }

                    Button {
                        text: "OK"
                        width: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: invalidGuessPopup.close()
                        background: Rectangle {
                            color: "#FF4C4C"
                            radius: 5
                        }

                        contentItem: Text {
                            text: "OK"
                            color: "black"
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.pixelSize: 16
                        }
                    }
                }

                // Handle key events within the Popup
                Keys.onPressed: {
                    if (event.key === Qt.Key_Escape) {
                        invalidGuessPopup.close()
                        event.accepted = true
                    }
                }
            }
        }
    }

    // Custom Pop-Up Overlay for short guess
    Popup {
        id: shortGuessPopup
        modal: true
        focus: true
        width: 300
        height: 150
        z: 10
        anchors.centerIn: parent

        Rectangle {
            anchors.fill: parent
            color: "#FFFFE6"
            radius: 10
            border.color: "#FFD700"
            border.width: 2

            // Use a FocusScope to handle key events inside the Popup
            FocusScope {
                anchors.fill: parent
                focus: true

                Column {
                    anchors.centerIn: parent
                    spacing: 20

                    Text {
                        text: "Word must be 5 letters!"
                        font.pixelSize: 16
                        wrapMode: Text.Wrap
                    }

                    Button {
                        text: "OK"
                        width: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: shortGuessPopup.close()
                        background: Rectangle {
                            color: "#FFD700"
                            radius: 5
                        }

                        contentItem: Text {
                            text: "OK"
                            color: "black"
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.pixelSize: 16
                        }
                    }
                }

                // Handle key events within the Popup
                Keys.onPressed: {
                    if (event.key === Qt.Key_Escape) {
                        shortGuessPopup.close()
                        event.accepted = true
                    }
                }
            }
        }
    }

    // Item to capture key inputs
    Item {
        id: keyInputHandler
        anchors.fill: parent
        focus: true

        Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                handleKeyInput("Enter")
                event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                handleKeyInput("Backspace")
                event.accepted = true
            } else if (/^[A-Za-z]$/.test(event.text) && currentCol < 5) {
                handleKeyInput(event.text.toUpperCase())
            }
        }
    }

    // New Game Button
    Button {

        anchors.top: gameGrid.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5
        anchors.topMargin: 20
        width: 120
        height: 40

        background: Rectangle {
            anchors.fill: parent
            color: "#C0EBA6"
            radius: 8
            border.color: "#C0EBA6"
            border.width: 2
        }

        contentItem: Text {
            text: "New Game"
            color: "black"
            font.pixelSize: 18
            font.bold: true
            anchors.centerIn: parent
        }

        onClicked: {
            gameLogic.startNewGame()
            gameOverFlag = false
            resetGameData()
            resetKeyboardStatus()
            console.log("New game started. Target word:", gameLogic.targetWord)
            keyInputHandler.forceActiveFocus()
            resetGameStatus()
        }
    }

    // Game Status Message
    Text {
        id: gameStatus
        text: ""
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        visible: false
        font.pixelSize: 20
        color: "blue"
    }

    // Handle GameLogic signals
    Connections {
        target: gameLogic

        onGuessResult: function (statuses) {
            console.log("Guess statuses:", statuses)

            // Update grid status
            for (var i = 0; i < statuses.length; i++) {
                var gridIndex = currentRow * 5 + i
                statusData[gridIndex] = statuses[i] // Update the grid's status
            }

            // Update keyboard status
            for (var j = 0; j < statuses.length; j++) {
                var letter = gridData[currentRow * 5 + j].toUpperCase()
                if (keyboardStatus.hasOwnProperty(letter)) {
                    // If the letter is already green, keep it green
                    if (keyboardStatus[letter] === "green") {
                        continue
                    }

                    if (statuses[j] === "correct") {
                        keyboardStatus[letter] = "green" // Turn green
                    } else if (statuses[j] === "present"
                               && keyboardStatus[letter] !== "green") {
                        keyboardStatus[letter] = "yellow" // Turn yellow if not already green
                    } else if (statuses[j] === "absent"
                               && keyboardStatus[letter] !== "yellow"
                               && keyboardStatus[letter] !== "green") {
                        keyboardStatus[letter] = "gray" // Mark as absent
                    }
                }
            }

            // Trigger bindings by creating a new reference
            keyboardStatus = Object.assign({}, keyboardStatus)
            statusData = statusData.slice()
        }

        onGameOver: function (won) {
            gameOverFlag = true
            gameStatus.text = won ? "You Won!" : "Game Over! The word was: " + gameLogic.targetWord
            gameStatus.visible = true
        }

        onTargetWordChanged: function () {
            console.log("New target word:", gameLogic.targetWord)
        }

        onInvalidGuess: function () {
            console.log("Invalid guess received.")
            invalidGuessPopup.open()
        }
    }
}
