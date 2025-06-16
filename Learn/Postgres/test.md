# Android Tic-Tac-Toe Game

## Project Structure

```
app/
├── src/main/
│   ├── java/com/tictactoe/
│   │   ├── MainActivity.kt
│   │   ├── GameActivity.kt
│   │   ├── GameLogic.kt
│   │   ├── AIPlayer.kt
│   │   └── GameState.kt
│   ├── res/
│   │   ├── layout/
│   │   │   ├── activity_main.xml
│   │   │   ├── activity_game.xml
│   │   │   └── cell_item.xml
│   │   ├── values/
│   │   │   ├── colors.xml
│   │   │   ├── strings.xml
│   │   │   └── styles.xml
│   │   └── drawable/
│   │       ├── cell_background.xml
│   │       ├── button_style.xml
│   │       └── winning_line.xml
│   └── AndroidManifest.xml
└── build.gradle
```

## build.gradle (Module: app)

```gradle
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.tictactoe'
    compileSdk 34

    defaultConfig {
        applicationId "com.tictactoe"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
    buildFeatures {
        viewBinding true
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0'
    implementation 'androidx.activity:activity-ktx:1.8.2'
    
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
```

## AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <application
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.TicTacToe"
        tools:targetApi="31">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.TicTacToe">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
        <activity
            android:name=".GameActivity"
            android:exported="false"
            android:screenOrientation="portrait" />
    </application>
</manifest>
```

## GameState.kt

```kotlin
package com.tictactoe

enum class Player {
    X, O, NONE
}

enum class GameMode {
    TWO_PLAYER, SINGLE_PLAYER
}

enum class Difficulty {
    EASY, MEDIUM
}

data class GameState(
    val board: Array<Array<Player>> = Array(3) { Array(3) { Player.NONE } },
    val currentPlayer: Player = Player.X,
    val gameMode: GameMode = GameMode.TWO_PLAYER,
    val difficulty: Difficulty = Difficulty.MEDIUM,
    val isGameOver: Boolean = false,
    val winner: Player = Player.NONE,
    val winningLine: List<Pair<Int, Int>> = emptyList(),
    val xWins: Int = 0,
    val oWins: Int = 0,
    val draws: Int = 0
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as GameState

        if (!board.contentDeepEquals(other.board)) return false
        if (currentPlayer != other.currentPlayer) return false
        if (gameMode != other.gameMode) return false
        if (difficulty != other.difficulty) return false
        if (isGameOver != other.isGameOver) return false
        if (winner != other.winner) return false
        if (winningLine != other.winningLine) return false
        if (xWins != other.xWins) return false
        if (oWins != other.oWins) return false
        if (draws != other.draws) return false

        return true
    }

    override fun hashCode(): Int {
        var result = board.contentDeepHashCode()
        result = 31 * result + currentPlayer.hashCode()
        result = 31 * result + gameMode.hashCode()
        result = 31 * result + difficulty.hashCode()
        result = 31 * result + isGameOver.hashCode()
        result = 31 * result + winner.hashCode()
        result = 31 * result + winningLine.hashCode()
        result = 31 * result + xWins
        result = 31 * result + oWins
        result = 31 * result + draws
        return result
    }
}
```

## GameLogic.kt

```kotlin
package com.tictactoe

class GameLogic {
    
    fun makeMove(gameState: GameState, row: Int, col: Int): GameState {
        if (gameState.isGameOver || gameState.board[row][col] != Player.NONE) {
            return gameState
        }
        
        val newBoard = gameState.board.map { it.clone() }.toTypedArray()
        newBoard[row][col] = gameState.currentPlayer
        
        val (isOver, winner, winningLine) = checkGameEnd(newBoard)
        
        val newGameState = gameState.copy(
            board = newBoard,
            currentPlayer = if (gameState.currentPlayer == Player.X) Player.O else Player.X,
            isGameOver = isOver,
            winner = winner,
            winningLine = winningLine
        )
        
        return if (isOver) {
            updateScore(newGameState, winner)
        } else {
            newGameState
        }
    }
    
    private fun checkGameEnd(board: Array<Array<Player>>): Triple<Boolean, Player, List<Pair<Int, Int>>> {
        // Check rows
        for (i in 0..2) {
            if (board[i][0] != Player.NONE && 
                board[i][0] == board[i][1] && 
                board[i][1] == board[i][2]) {
                return Triple(true, board[i][0], listOf(Pair(i, 0), Pair(i, 1), Pair(i, 2)))
            }
        }
        
        // Check columns
        for (j in 0..2) {
            if (board[0][j] != Player.NONE && 
                board[0][j] == board[1][j] && 
                board[1][j] == board[2][j]) {
                return Triple(true, board[0][j], listOf(Pair(0, j), Pair(1, j), Pair(2, j)))
            }
        }
        
        // Check diagonals
        if (board[0][0] != Player.NONE && 
            board[0][0] == board[1][1] && 
            board[1][1] == board[2][2]) {
            return Triple(true, board[0][0], listOf(Pair(0, 0), Pair(1, 1), Pair(2, 2)))
        }
        
        if (board[0][2] != Player.NONE && 
            board[0][2] == board[1][1] && 
            board[1][1] == board[2][0]) {
            return Triple(true, board[0][2], listOf(Pair(0, 2), Pair(1, 1), Pair(2, 0)))
        }
        
        // Check for draw
        if (board.all { row -> row.all { it != Player.NONE } }) {
            return Triple(true, Player.NONE, emptyList())
        }
        
        return Triple(false, Player.NONE, emptyList())
    }
    
    private fun updateScore(gameState: GameState, winner: Player): GameState {
        return when (winner) {
            Player.X -> gameState.copy(xWins = gameState.xWins + 1)
            Player.O -> gameState.copy(oWins = gameState.oWins + 1)
            Player.NONE -> gameState.copy(draws = gameState.draws + 1)
        }
    }
    
    fun resetGame(gameState: GameState): GameState {
        return gameState.copy(
            board = Array(3) { Array(3) { Player.NONE } },
            currentPlayer = Player.X,
            isGameOver = false,
            winner = Player.NONE,
            winningLine = emptyList()
        )
    }
    
    fun resetScore(gameState: GameState): GameState {
        return gameState.copy(
            xWins = 0,
            oWins = 0,
            draws = 0
        )
    }
    
    fun getAvailableMoves(board: Array<Array<Player>>): List<Pair<Int, Int>> {
        val moves = mutableListOf<Pair<Int, Int>>()
        for (i in 0..2) {
            for (j in 0..2) {
                if (board[i][j] == Player.NONE) {
                    moves.add(Pair(i, j))
                }
            }
        }
        return moves
    }
}
```

## AIPlayer.kt

```kotlin
package com.tictactoe

import kotlin.random.Random

class AIPlayer(private val gameLogic: GameLogic) {
    
    fun makeMove(gameState: GameState): Pair<Int, Int>? {
        val availableMoves = gameLogic.getAvailableMoves(gameState.board)
        if (availableMoves.isEmpty()) return null
        
        return when (gameState.difficulty) {
            Difficulty.EASY -> makeEasyMove(availableMoves)
            Difficulty.MEDIUM -> makeMediumMove(gameState, availableMoves)
        }
    }
    
    private fun makeEasyMove(availableMoves: List<Pair<Int, Int>>): Pair<Int, Int> {
        // 70% random, 30% strategic
        return if (Random.nextFloat() < 0.7f) {
            availableMoves.random()
        } else {
            availableMoves.first()
        }
    }
    
    private fun makeMediumMove(gameState: GameState, availableMoves: List<Pair<Int, Int>>): Pair<Int, Int> {
        val aiPlayer = gameState.currentPlayer
        val humanPlayer = if (aiPlayer == Player.X) Player.O else Player.X
        
        // 1. Check if AI can win
        for (move in availableMoves) {
            val testBoard = gameState.board.map { it.clone() }.toTypedArray()
            testBoard[move.first][move.second] = aiPlayer
            if (checkWin(testBoard, aiPlayer)) {
                return move
            }
        }
        
        // 2. Check if AI needs to block human from winning
        for (move in availableMoves) {
            val testBoard = gameState.board.map { it.clone() }.toTypedArray()
            testBoard[move.first][move.second] = humanPlayer
            if (checkWin(testBoard, humanPlayer)) {
                return move
            }
        }
        
        // 3. Take center if available
        if (gameState.board[1][1] == Player.NONE) {
            return Pair(1, 1)
        }
        
        // 4. Take corners
        val corners = listOf(Pair(0, 0), Pair(0, 2), Pair(2, 0), Pair(2, 2))
        val availableCorners = corners.filter { it in availableMoves }
        if (availableCorners.isNotEmpty()) {
            return availableCorners.random()
        }
        
        // 5. Take any available move
        return availableMoves.random()
    }
    
    private fun checkWin(board: Array<Array<Player>>, player: Player): Boolean {
        // Check rows
        for (i in 0..2) {
            if (board[i][0] == player && board[i][1] == player && board[i][2] == player) {
                return true
            }
        }
        
        // Check columns
        for (j in 0..2) {
            if (board[0][j] == player && board[1][j] == player && board[2][j] == player) {
                return true
            }
        }
        
        // Check diagonals
        if (board[0][0] == player && board[1][1] == player && board[2][2] == player) {
            return true
        }
        
        if (board[0][2] == player && board[1][1] == player && board[2][0] == player) {
            return true
        }
        
        return false
    }
}
```

## MainActivity.kt

```kotlin
package com.tictactoe

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.tictactoe.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupClickListeners()
    }
    
    private fun setupClickListeners() {
        binding.btnTwoPlayer.setOnClickListener {
            startGame(GameMode.TWO_PLAYER, Difficulty.MEDIUM)
        }
        
        binding.btnSinglePlayerEasy.setOnClickListener {
            startGame(GameMode.SINGLE_PLAYER, Difficulty.EASY)
        }
        
        binding.btnSinglePlayerMedium.setOnClickListener {
            startGame(GameMode.SINGLE_PLAYER, Difficulty.MEDIUM)
        }
    }
    
    private fun startGame(gameMode: GameMode, difficulty: Difficulty) {
        val intent = Intent(this, GameActivity::class.java).apply {
            putExtra("GAME_MODE", gameMode.name)
            putExtra("DIFFICULTY", difficulty.name)
        }
        startActivity(intent)
    }
}
```

## GameActivity.kt

```kotlin
package com.tictactoe

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.Button
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.tictactoe.databinding.ActivityGameBinding

class GameActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityGameBinding
    private lateinit var gameLogic: GameLogic
    private lateinit var aiPlayer: AIPlayer
    private var gameState: GameState = GameState()
    private lateinit var boardButtons: Array<Array<Button>>
    private val handler = Handler(Looper.getMainLooper())
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityGameBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        initializeGame()
        setupBoard()
        setupClickListeners()
        updateUI()
    }
    
    private fun initializeGame() {
        gameLogic = GameLogic()
        aiPlayer = AIPlayer(gameLogic)
        
        val gameMode = GameMode.valueOf(intent.getStringExtra("GAME_MODE") ?: "TWO_PLAYER")
        val difficulty = Difficulty.valueOf(intent.getStringExtra("DIFFICULTY") ?: "MEDIUM")
        
        gameState = gameState.copy(gameMode = gameMode, difficulty = difficulty)
    }
    
    private fun setupBoard() {
        boardButtons = arrayOf(
            arrayOf(binding.btn00, binding.btn01, binding.btn02),
            arrayOf(binding.btn10, binding.btn11, binding.btn12),
            arrayOf(binding.btn20, binding.btn21, binding.btn22)
        )
        
        for (i in 0..2) {
            for (j in 0..2) {
                boardButtons[i][j].setOnClickListener { onCellClicked(i, j) }
            }
        }
    }
    
    private fun setupClickListeners() {
        binding.btnNewGame.setOnClickListener { newGame() }
        binding.btnResetScore.setOnClickListener { resetScore() }
        binding.btnBack.setOnClickListener { finish() }
    }
    
    private fun onCellClicked(row: Int, col: Int) {
        if (gameState.isGameOver || gameState.board[row][col] != Player.NONE) {
            return
        }
        
        // Human move
        gameState = gameLogic.makeMove(gameState, row, col)
        updateUI()
        
        // AI move (if in single player mode and game is not over)
        if (gameState.gameMode == GameMode.SINGLE_PLAYER && !gameState.isGameOver) {
            handler.postDelayed({
                val aiMove = aiPlayer.makeMove(gameState)
                aiMove?.let { (aiRow, aiCol) ->
                    gameState = gameLogic.makeMove(gameState, aiRow, aiCol)
                    updateUI()
                }
            }, 500) // Small delay for better UX
        }
    }
    
    private fun updateUI() {
        updateBoard()
        updateGameInfo()
        updateScore()
        
        if (gameState.isGameOver) {
            showGameResult()
        }
    }
    
    private fun updateBoard() {
        for (i in 0..2) {
            for (j in 0..2) {
                val button = boardButtons[i][j]
                when (gameState.board[i][j]) {
                    Player.X -> {
                        button.text = "X"
                        button.setTextColor(ContextCompat.getColor(this, R.color.player_x))
                    }
                    Player.O -> {
                        button.text = "O"
                        button.setTextColor(ContextCompat.getColor(this, R.color.player_o))
                    }
                    Player.NONE -> {
                        button.text = ""
                    }
                }
                
                // Highlight winning line
                if (gameState.winningLine.contains(Pair(i, j))) {
                    button.setBackgroundColor(ContextCompat.getColor(this, R.color.winning_cell))
                } else {
                    button.setBackgroundColor(ContextCompat.getColor(this, R.color.cell_background))
                }
            }
        }
    }
    
    private fun updateGameInfo() {
        val modeText = if (gameState.gameMode == GameMode.TWO_PLAYER) {
            "Two Player"
        } else {
            "vs AI (${gameState.difficulty.name.lowercase().replaceFirstChar { it.uppercase() }})"
        }
        
        binding.tvGameMode.text = modeText
        
        val turnText = if (gameState.isGameOver) {
            "Game Over"
        } else {
            "${gameState.currentPlayer}'s Turn"
        }
        
        binding.tvCurrentPlayer.text = turnText
    }
    
    private fun updateScore() {
        binding.tvScore.text = "X: ${gameState.xWins}  |  O: ${gameState.oWins}  |  Draws: ${gameState.draws}"
    }
    
    private fun showGameResult() {
        val message = when (gameState.winner) {
            Player.X -> "Player X Wins!"
            Player.O -> "Player O Wins!"
            Player.NONE -> "It's a Draw!"
        }
        
        Toast.makeText(this, message, Toast.LENGTH_LONG).show()
    }
    
    private fun newGame() {
        gameState = gameLogic.resetGame(gameState)
        updateUI()
    }
    
    private fun resetScore() {
        gameState = gameLogic.resetScore(gameState)
        updateUI()
    }
}
```

## Layout Files

### activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center"
    android:padding="32dp"
    android:background="@color/background">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="@string/app_name"
        android:textSize="36sp"
        android:textStyle="bold"
        android:textColor="@color/primary_text"
        android:layout_marginBottom="48dp" />

    <Button
        android:id="@+id/btn_two_player"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Two Player Mode"
        android:textSize="18sp"
        android:layout_marginBottom="16dp"
        style="@style/GameButton" />

    <Button
        android:id="@+id/btn_single_player_easy"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Single Player (Easy)"
        android:textSize="18sp"
        android:layout_marginBottom="16dp"
        style="@style/GameButton" />

    <Button
        android:id="@+id/btn_single_player_medium"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Single Player (Medium)"
        android:textSize="18sp"
        style="@style/GameButton" />

</LinearLayout>
```

### activity_game.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="@color/background">

    <!-- Header -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center_vertical"
        android:layout_marginBottom="16dp">

        <Button
            android:id="@+id/btn_back"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="← Back"
            android:textSize="14sp"
            style="@style/SecondaryButton" />

        <View
            android:layout_width="0dp"
            android:layout_height="1dp"
            android:layout_weight="1" />

        <TextView
            android:id="@+id/tv_game_mode"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Two Player"
            android:textSize="16sp"
            android:textColor="@color/secondary_text" />

    </LinearLayout>

    <!-- Current Player -->
    <TextView
        android:id="@+id/tv_current_player"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="X's Turn"
        android:textSize="24sp"
        android:textStyle="bold"
        android:textColor="@color/primary_text"
        android:gravity="center"
        android:layout_marginBottom="24dp" />

    <!-- Game Board -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:gravity="center"
        android:layout_marginBottom="24dp">

        <LinearLayout
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="horizontal">

            <Button
                android:id="@+id/btn_00"
                style="@style/CellButton" />

            <Button
                android:id="@+id/btn_01"
                style="@style/CellButton" />

            <Button
                android:id="@+id/btn_02"
                style="@style/CellButton" />

        </LinearLayout>

        <LinearLayout
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="horizontal">

            <Button
                android:id="@+id/btn_10"
                style="@style/CellButton" />

            <Button
                android:id="@+id/btn_11"
                style="@style/CellButton" />

            <Button
                android:id="@+id/btn_12"
                style="@style/CellButton" />

        </LinearLayout>

        <LinearLayout
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="horizontal">

            <Button
                android:id="@+id/btn_20"
                style="@style/CellButton" />

            <Button
                android:id="@+id/btn_21"
                style="@style/CellButton" />

            <Button
                android:id="@+id/btn_22"
                style="@style/CellButton" />

        </LinearLayout>

    </LinearLayout>

    <!-- Score -->
    <TextView
        android:id="@+id/tv_score"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="X: 0  |  O: 0  |  Draws: 0"
        android:textSize="18sp"
        android:textColor="@color/primary_text"
        android:gravity="center"
        android:layout_marginBottom="24dp" />

    <!-- Control Buttons -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center">

        <Button
            android:id="@+id/btn_new_game"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="New Game"
            android:layout_marginEnd="8dp"
            style="@style/GameButton" />

        <Button
            android:id="@+id/btn_reset_score"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="Reset Score"
            android:layout_marginStart="8dp"
            style="@style/SecondaryButton" />

    </LinearLayout>

</LinearLayout>
```

## Resource Files

### colors.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="primary">#1976D2</color>
    <color name="primary_dark">#1565C0</color>
    <color name="accent">#FF4081</color>
    
    <color name="background">#F5F5F5</color>
    <color name="surface">#FFFFFF</color>
    
    <color name="primary_text">#212121</color>
    <color name="secondary_text">#757575</color>
    
    <color name="player_x">#E53935</color>
    <color name="player_o">#1E88E5</color>
    
    <color name="cell_background">#FFFFFF</color>
    <color name="cell_border">#E0E0E0</color>
    <color name="winning_cell">#4CAF50</color>
    
    <color name="button_primary">#1976D2</color>
    <color name="button_secondary">#757575</color>
</resources>
```

### strings.xml

```xml
<resources>
    <string name="app_name">Tic Tac Toe</string>
</resources>
```

### styles.xml

```xml
<resources>
    <style name="Theme.TicTacToe" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">@color/primary</item>
        <item name="colorPrimaryDark">@color/primary_dark</item>
        <item name="colorAccent">@color/accent</item>
        <item name="android:windowBackground">@color/background</item>
    </style>

    <style name="GameButton">
        <item name="android:layout_width">match_parent</item>
        <item name="android:layout_height">56dp</item>
        <item name="android:backgroundTint">@color/button_primary</item>
        <item name="android:textColor">@android:color/white</item>
        <item name="android:textSize">16sp</item>
        <item name="android:textStyle">bold</item>
        <item name="cornerRadius">8dp</item>
    </style>

    <style name="SecondaryButton">
        <item name="android:layout_width">wrap_content
```