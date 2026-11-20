#!/bin/bash

# Configuration
DATA_FILE="movies.csv"
USER_PREFS="user_preferences.txt"

if [ ! -f "$DATA_FILE" ]; then
        echo "ERROR: $DATA_FILE not found! Please run the Python cleaning script first."
        exit 1
fi

show_help() {
        echo "Usage: ./movie_recommender.sh [OPTIONS]"
        echo "You can combine multiple options on the same line:"
        echo "  --genre <genre1,genre2> Filter by one or multiple genres (e.g., 'Action, Sci-Fi')"
        echo "  --search <keyword>      Search all text (uses grep)"
        echo "  --min-rating <rating>   Filter by minimum rating"
        echo "  --year <start-end>      Filter by year range"
        echo "  --director <name>       Filter by director name"
        echo "  --rate                  Rate a movie"
        echo "  --menu                  Launch interactive menu"
        echo "Example: ./movie_recommender.sh --genre Action --min-rating 8.0 --year 2000-2010"
}

# ---------------------------------------------------------
# MAIN FILTER FUNCTION
# ---------------------------------------------------------
filter_movies() {
        local genre="$1"
        local min_rating="$2"
        local year_range="$3"
        local director="$4"

        echo "----------------------------------------------------------------------------------------------------------"
        printf "%-12s | %-45s | %-6s | %-25s | %-8s | %s\n" "ID" "TITLE" "YEAR" "GENRE" "RATING" "DIRECTOR"
        echo "----------------------------------------------------------------------------------------------------------"

        awk -F, -v genre="$genre" -v rating="$min_rating" -v years="$year_range" -v dir="$director" '
        BEGIN {
                gsub(/,/, " ", genre) 
                num_genres = split(genre, genres, " ")
        }
        NR > 1 {
                id = $1; title = $2; year = $3; g = $4; r = $5; d = $7
                
                if (length(d) == 0) { d = $8 }

                match_found = 1

                # --- STRICT MULTI-GENRE LOGIC (AND) ---
                if (num_genres > 0) {
                        for (i = 1; i <= num_genres; i++) {
                                if (tolower(g) !~ tolower(genres[i])) {
                                        match_found = 0
                                        break
                                }
                        }
                }

                # --- OTHER FILTERS ---
                if (rating != "" && (length(r) == 0 || r < rating)) {
                        match_found=0
                }

                if (dir != "" && (length(d) == 0 || tolower(d) !~ tolower(dir))) {
                        match_found=0
                }

                if (years != "") {
                        split(years, yarr, "-")
                        start_year=yarr[1]
                        end_year=yarr[2]
                        if (length(year) == 0 || year < start_year || year > end_year) {
                                match_found=0
                        }
                }

                if (match_found) {
                        if (length(r) == 0) { r = "N/A" }
                        if (length(year) == 0) { year = "N/A" }
                        if (length(d) == 0) { d = "N/A" }
                        
                        printf "%-12s | %-45s | %-6s | %-25s | %-8s | %s\n", id, title, year, g, r, d
                }
        }' "$DATA_FILE"
        echo "----------------------------------------------------------------------------------------------------------"
}

# ---------------------------------------------------------
# GREP SEARCH FUNCTION
# ---------------------------------------------------------
search_movies() {
    local keyword="$1"
    echo "----------------------------------------------------------------------------------------------------------"
    printf "%-12s | %-45s | %-6s | %-25s | %-8s | %s\n" "ID" "TITLE" "YEAR" "GENRE" "RATING" "DIRECTOR"
    echo "----------------------------------------------------------------------------------------------------------"
    
    grep -i "$keyword" "$DATA_FILE" | awk -F, '{
        id = $1; title = $2; year = $3; g = $4; r = $5; d = $7;
        if (length(d) == 0) { d = $8 }
        if (length(r) == 0) { r = "N/A" }
        if (length(year) == 0) { year = "N/A" }
        if (length(d) == 0) { d = "N/A" }
        
        printf "%-12s | %-45s | %-6s | %-25s | %-8s | %s\n", id, title, year, g, r, d
    }'
    echo "----------------------------------------------------------------------------------------------------------"
}

# ---------------------------------------------------------
# RATING FUNCTION
# ---------------------------------------------------------
rate_movie() {
        echo "Enter Movie ID to rate:"
        read -r movie_id
        echo "Enter New Rating (0.0 - 10.0):"
        read -r new_rating

        if ! grep -q "^$movie_id," "$DATA_FILE"; then
                echo "Movie ID not found."
                return
        fi

        cp "$DATA_FILE" "$DATA_FILE.bak"

        sed -i -E "s/^($movie_id,[^,]+,[^,]+,[^,]+,)[^,]+(,.*)/\1$new_rating\2/" "$DATA_FILE"

        echo "Rating updated successfully!"
        echo "User rated Movie ID $movie_id: $new_rating" >> "$USER_PREFS"
}

# ---------------------------------------------------------
# COMMAND LINE HANDLING (SUPPORTS MULTIPLE FLAGS)
# ---------------------------------------------------------
if [ $# -gt 0 ]; then
    # If they just typed --menu, skip straight to the dialog menu
    if [ "$1" == "--menu" ]; then
        :
    else
        # Variables to hold our search criteria
        CLI_GENRE=""
        CLI_RATING=""
        CLI_YEAR=""
        CLI_DIRECTOR=""

        # Loop through every argument provided
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --genre)
                    # Grab all words until the next -- flag (allows spaces in names without quotes)
                    shift
                    GENRE_STR=""
                    while [[ $# -gt 0 && "$1" != --* ]]; do
                        GENRE_STR="$GENRE_STR $1"
                        shift
                    done
                    CLI_GENRE="$GENRE_STR"
                    ;;
                --min-rating)
                    CLI_RATING="$2"
                    shift 2
                    ;;
                --year)
                    CLI_YEAR="$2"
                    shift 2
                    ;;
                --director)
                    shift
                    DIR_STR=""
                    while [[ $# -gt 0 && "$1" != --* ]]; do
                        DIR_STR="$DIR_STR $1"
                        shift
                    done
                    CLI_DIRECTOR="$DIR_STR"
                    ;;
                --search)
                    search_movies "$2"
                    exit 0
                    ;;
                --rate)
                    rate_movie
                    exit 0
                    ;;
                --help)
                    show_help
                    exit 0
                    ;;
                *)
                    echo "Invalid option: $1. Use --help."
                    exit 1
                    ;;
            esac
        done

        # Run the filter with whatever combination of arguments was provided
        filter_movies "$CLI_GENRE" "$CLI_RATING" "$CLI_YEAR" "$CLI_DIRECTOR"
        exit 0
    fi
fi

# ---------------------------------------------------------
# INTERACTIVE MENU
# ---------------------------------------------------------
if ! command -v dialog &> /dev/null; then
    echo "dialog is not installed. Run with arguments instead (e.g., ./movie_recommender.sh --genre Action)"
    exit 1
fi

while true; do
    CHOICE=$(dialog --clear --backtitle "Movie Recommendation Engine" --title "Main Menu" \
            --menu "Choose an option:" 18 55 8 \
            1 "Recommend by Genre" \
            2 "Recommend by Period of Time" \
            3 "Recommend by Rating" \
            4 "Recommend by Director" \
            5 "Custom Search (All Filters)" \
            6 "Search by Keyword (grep)" \
            7 "Rate a Movie (sed)" \
            8 "Exit" \
            2>&1 >/dev/tty)

    clear
    case $CHOICE in
        1) GENRE=$(dialog --inputbox "Enter Genre(s) (e.g., Action, Comedy):" 8 50 2>&1 >/dev/tty); clear; filter_movies "$GENRE" "" "" ""; read -p "Press Enter to return..."; ;;
        2) YEAR=$(dialog --inputbox "Enter Year Range (e.g., 2000-2010):" 8 50 2>&1 >/dev/tty); clear; filter_movies "" "" "$YEAR" ""; read -p "Press Enter to return..."; ;;
        3) RATING=$(dialog --inputbox "Enter Minimum Rating (e.g., 8.5):" 8 50 2>&1 >/dev/tty); clear; filter_movies "" "$RATING" "" ""; read -p "Press Enter to return..."; ;;
        4) DIRECTOR=$(dialog --inputbox "Enter Director Name:" 8 50 2>&1 >/dev/tty); clear; filter_movies "" "" "" "$DIRECTOR"; read -p "Press Enter to return..."; ;;
        5) 
            C_GENRE=$(dialog --inputbox "Enter Genre(s) (or leave blank):" 8 50 2>&1 >/dev/tty)
            C_YEAR=$(dialog --inputbox "Enter Year Range (or leave blank):" 8 50 2>&1 >/dev/tty)
            C_RATING=$(dialog --inputbox "Enter Minimum Rating (or leave blank):" 8 50 2>&1 >/dev/tty)
            C_DIRECTOR=$(dialog --inputbox "Enter Director Name (or leave blank):" 8 50 2>&1 >/dev/tty)
            clear; filter_movies "$C_GENRE" "$C_RATING" "$C_YEAR" "$C_DIRECTOR"; read -p "Press Enter to return..."
            ;;
        6) KEYWORD=$(dialog --inputbox "Enter search keyword (e.g., Nolan):" 8 50 2>&1 >/dev/tty); clear; search_movies "$KEYWORD"; read -p "Press Enter to return..."; ;;
        7) clear; rate_movie; read -p "Press Enter to return..."; ;;
        8) clear; exit 0 ;;
    esac
done
