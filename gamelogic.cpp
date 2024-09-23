#include "gamelogic.h"
#include <QRandomGenerator>
#include <QTextStream>
#include <QDebug>
#include <QFile>

GameLogic::GameLogic(QObject *parent)
    : QObject(parent), m_currentRow(0), m_currentCol(0), m_attempts(0) {
    initializeWordList();
    startNewGame();
}

QStringList GameLogic::grid() const {
    return m_grid;
}

int GameLogic::currentRow() const {
    return m_currentRow;
}

int GameLogic::currentCol() const {
    return m_currentCol;
}

QString GameLogic::targetWord() const {
    return m_targetWord;
}


void GameLogic::initializeWordList() {
    QFile file(":/dictionary/dictionary.txt"); // Ensure the path matches your .qrc
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Failed to open dictionary.txt";
        return;
    }

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString word = in.readLine().trimmed().toUpper();
        if (word.length() == 5) { // Only five-letter words
            m_wordList << word;
        }
    }
    file.close();
    qDebug() << "Loaded" << m_wordList.size() << "words.";
}

bool GameLogic::isValidGuess(const QString &guess) {
    // Check if the guess is exactly 5 letters and exists in the word list
    return guess.length() == 5 && m_wordList.contains(guess.toUpper());
}

QStringList GameLogic::evaluateGuess(const QString &guess) {
    QStringList statuses;
    QList<bool> solutionCharsTaken;
    QList<bool> guessCharsTaken;

    // Initialize lists with false values
    for (int i = 0; i < m_targetWord.length(); ++i) {
        solutionCharsTaken.append(false);
    }
    for (int i = 0; i < guess.length(); ++i) {
        guessCharsTaken.append(false);
    }

    // Initialize statuses with empty strings
    for (int i = 0; i < guess.length(); ++i) {
        statuses.append("");
    }

    // Correct Cases
    for (int i = 0; i < guess.length(); ++i) {
        if (guess[i].toUpper() == m_targetWord[i].toUpper()) {
            statuses[i] = "correct";
            solutionCharsTaken[i] = true;
            guessCharsTaken[i] = true;
        }
    }

    // Present and Absent Cases
    for (int i = 0; i < guess.length(); ++i) {
        if (statuses[i] == "correct") {
            continue;
        }

        bool found = false;
        for (int j = 0; j < m_targetWord.length(); ++j) {
            if (!solutionCharsTaken[j] && guess[i].toUpper() == m_targetWord[j].toUpper()) {
                found = true;
                solutionCharsTaken[j] = true;
                break;
            }
        }

        if (found) {
            statuses[i] = "present";
        } else {
            statuses[i] = "absent";
        }
    }

    return statuses;
}

void GameLogic::submitGuess() {
    qDebug() << "submitGuess() called.";
    if (m_currentCol != 5) {
        qDebug() << "Guess not complete.";
        emit invalidGuess();
        return; // Guess not complete
    }

    // Collect the guess from the grid
    QStringList guessList;
    for(int i=0; i < 5; ++i) {
        guessList << m_grid[m_currentRow * 5 + i];
    }

    QString guessWord = guessList.join("").toUpper();
    qDebug() << "Submitting guess:" << guessWord;

    if (!isValidGuess(guessWord)) {
        qDebug() << "Invalid guess word.";
        emit invalidGuess();
        return;
    }

    QStringList statuses = evaluateGuess(guessWord);
    emit guessResult(statuses);

    m_attempts++;

    if (guessWord == m_targetWord.toUpper()) {
        qDebug() << "User has won!";
        emit gameOver(true); // Win
    } else if (m_attempts >= 6) {
        qDebug() << "User has lost!";
        emit gameOver(false); // Lose
    } else {
        m_currentRow++;
        m_currentCol = 0;
        emit currentRowChanged();
        emit currentColChanged();
        emit gridChanged();
    }
}

void GameLogic::addLetter(const QString &letter) {
    if (m_currentCol < 5 && m_currentRow < 6) {
        m_grid[m_currentRow * 5 + m_currentCol] = letter;
        m_currentCol++;
        emit gridChanged();
        emit currentColChanged();
    }
}

void GameLogic::removeLetter() {
    if (m_currentCol > 0) {
        m_currentCol--;
        m_grid[m_currentRow * 5 + m_currentCol] = "";
        emit gridChanged();
        emit currentColChanged();
    }
}

void GameLogic::startNewGame() {
    int randomIndex = QRandomGenerator::global()->bounded(m_wordList.size());
    m_targetWord = m_wordList[randomIndex].toUpper();
    m_attempts = 0;
    m_currentRow = 0;
    m_currentCol = 0;

    // Reset the grid
    m_grid = QStringList();
    for(int i=0; i < 6 * 5; ++i) {
        m_grid << "";
    }

    emit gridChanged();
    emit currentRowChanged();
    emit currentColChanged();
    emit targetWordChanged();
    qDebug() << "New game started. Target word:" << m_targetWord;
}
