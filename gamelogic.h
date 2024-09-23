#ifndef GAMELOGIC_H
#define GAMELOGIC_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QList>

class GameLogic : public QObject {
    Q_OBJECT
    Q_PROPERTY(QStringList grid READ grid NOTIFY gridChanged)
    Q_PROPERTY(int currentRow READ currentRow NOTIFY currentRowChanged)
    Q_PROPERTY(int currentCol READ currentCol NOTIFY currentColChanged)
    Q_PROPERTY(QString targetWord READ targetWord NOTIFY targetWordChanged)

public:
    explicit GameLogic(QObject *parent = nullptr);

    // Getter methods for properties
    QStringList grid() const;
    int currentRow() const;
    int currentCol() const;
    QString targetWord() const;

public slots:
    // Slots to handle game actions
    void addLetter(const QString &letter);
    void removeLetter();
    void submitGuess();
    void startNewGame();

signals:
    // Signals to notify QML of changes
    void gridChanged();
    void currentRowChanged();
    void currentColChanged();
    void targetWordChanged();
    void gameOver(bool won);
    void guessResult(const QStringList &statuses);
    void invalidGuess();

private:
    // Private member variables
    QStringList m_grid; // Flat list of 30 elements (6 rows x 5 columns)
    int m_currentRow;
    int m_currentCol;
    QString m_targetWord;
    QStringList m_wordList;
    int m_attempts;

    // Helper methods
    void initializeWordList();
    bool isValidGuess(const QString &guess);
    QStringList evaluateGuess(const QString &guess);
};

#endif // GAMELOGIC_H
