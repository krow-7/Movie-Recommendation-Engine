# Movie Recommendation Engine

A command-line tool written in Bash that recommends movies based on user preferences, ratings, genres, and release years. It utilizes a local CSV dataset and features both a direct Command Line Interface (CLI) and an Interactive Text User Interface (TUI).

## Objective
This project demonstrates shell scripting proficiency by creating a functional recommendation engine. It fulfills the requirement of filtering a movie dataset while utilizing core Linux text-processing utilities.

## Features

*   **Data Management:** Reads from a structured CSV file (`movies.csv`).
*   **Dynamic Filtering:** 
    *   Filter by one or multiple **Genres** (strict AND logic).
    *   Filter by **Period of Time** (Year ranges, e.g., `2000-2010`).
    *   Filter by **Minimum Rating**.
    *   Filter by **Director**.
    *   Combine multiple filters on a single line.
*   **Interactive Menu:** A TUI powered by `dialog` for easy navigation.
*   **User Feedback:** Users can rate movies, updating the dataset and logging the action to a separate file.

## Tools Used

| Tool | Purpose in Project |
| :--- | :--- |
| **`awk`** | Core filtering engine. Parses the CSV and compares ratings, years, and genres. |
| **`grep`** | Used for keyword searching and verifying Movie IDs exist before rating. |
| **`sed`** | Used in-place to update the Rating column of a specific movie. |
| **`dialog`** | Builds the Interactive Menu for the user. |
| **`printf`** | Formats and aligns the output into a clean table. |
| **`cut`** | Trims overly long text to keep the terminal output readable. |

## Installation & Setup

### Prerequisites
*   **Bash Shell** (Linux, macOS, or Git Bash on Windows).
*   **`dialog` package** (Required for the Interactive Menu).
    *   Ubuntu/Debian: `sudo apt install dialog`
    *   macOS: `brew install dialog`
    *   Windows (MSYS2): `pacman -S dialog`

### Getting Started
1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/movie-recommender.git
   cd movie-recommender

2. Make it executable:
    chmod +x movie_recommender.sh

3. Interactive Menu
    open directory with msys2 ucrt64
    ./movie_recommender.sh

4. Command Line Interface
    filter by --genre, --min-rating, --year, and --director
    search: --search
    rate: --rate