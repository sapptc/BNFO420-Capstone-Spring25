import requests
import pandas as pd
from bs4 import BeautifulSoup
import time

# List of players to scrape
players = [
    "Maxx Williams", "Zach Kerr", "Tanner Vallejo", "D.J. Humphries",
    "Devon Kennard", "Javon Hagan", "Breon Borders", "Markus Golden",
    "Sean Harlow", "Andy Lee", "Rodney Hudson", "Jonathan Ward",
    "A.J. Green", "Demetrius Harris", "Corey Peters", "Zach Allen",
    "Chandler Jones", "Darrell Daniels", "Justin Pugh", "Jordan Phillips",
    "Andy Isabella", "Jason Spriggs", "Jonathan Bullard", "Jaylinn Hawkins",
    "Hayden Hurst", "Feleipe Franks", "Richie Grant", "Dorian Etheridge"
]  # Add more players as needed

base_url = "https://www.pro-football-reference.com"

def get_player_url(player_name):
    """Searches Pro Football Reference for a player's URL."""
    search_url = f"{base_url}/search/search.fcgi?search={player_name.replace(' ', '+')}"
    response = requests.get(search_url)
    soup = BeautifulSoup(response.text, "html.parser")
    
    # Try to find the first search result link
    link = soup.find("a", text=player_name)
    if link:
        return base_url + link["href"]
    return None

def get_player_stats(player_url, player_name):
    """Scrapes and saves a player's career stats as an Excel file."""
    response = requests.get(player_url)
    soup = BeautifulSoup(response.text, "html.parser")
    
    # Find stats table
    table = soup.find("table", {"id": "receiving"})  # Change ID for different stat categories
    if not table:
        table = soup.find("table", {"id": "rushing"})
    if not table:
        table = soup.find("table", {"id": "passing"})
    if not table:
        print(f"No stats found for {player_name}")
        return

    # Extract table data
    df = pd.read_html(str(table))[0]
    
    # Save as Excel file
    file_name = f"{player_name.replace(' ', '_')}_stats.xlsx"
    df.to_excel(file_name, index=False)
    print(f"Saved {player_name}'s stats to {file_name}")

# Loop through players, get their URLs, and scrape stats
for player in players:
    print(f"Searching for {player}...")
    url = get_player_url(player)
    if url:
        print(f"Found {player}'s page: {url}")
        get_player_stats(url, player)
    else:
        print(f"Could not find {player} on Pro Football Reference.")
    
    time.sleep(2)  # Pause to avoid hitting request limits
