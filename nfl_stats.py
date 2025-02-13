import pandas as pd
import sys
import os

def standardize_position(pos):
    """
    Standardize the position string.
    - All linebacker positions (LB, OLB, ILB, MLB, WLB, WILL, SLB, SAM) become "LB".
    - All cornerback positions (CB, NC, NCB, DC, DCB, DB) become "CB".
    - Returner positions (RET, KR, PR) become "RET".
    - Offensive line positions (OT, OG, G, C) become "OL".
    - Defensive line positions (DE, DT, NT) become "DL".
    - Safety positions (FS, SS) become "S".
    - Otherwise, return the original uppercased position.
    """
    pos = str(pos).strip().upper()
    lb_set = {"LB", "OLB", "ILB", "MLB", "WLB", "WILL", "SLB", "SAM"}
    cb_set = {"CB", "NC", "NCB", "DC", "DCB", "DB"}
    ret_set = {"RET", "KR", "PR"}
    ol_set = {"OT", "OG", "G", "C"}
    dl_set = {"DE", "DT", "NT"}
    s_set = {"FS", "SS"}
    
    if pos in lb_set:
        return "LB"
    elif pos in cb_set:
        return "CB"
    elif pos in ret_set:
        return "RET"
    elif pos in ol_set:
        return "OL"
    elif pos in dl_set:
        return "DL"
    elif pos in s_set:
        return "S"
    else:
        return pos

def main():
    # Prompt the user for the full file path and remove extra quotes if present.
    file_path = input("Enter the full path to the .xls file: ").strip()
    file_path = file_path.strip('\'"')

    if not file_path.lower().endswith(".xls"):
        print("wrong format error")
        sys.exit(1)
    if not os.path.exists(file_path):
        print("File not found.")
        sys.exit(1)

    # Read the .xls file with header on row 2.
    try:
        df = pd.read_excel(file_path, engine='xlrd', header=1)
    except Exception as e:
        print(f"Error reading the file: {e}")
        sys.exit(1)

    print("Columns found:", df.columns.tolist())

    # Verify required columns exist
    for col in ['Season', 'G', 'Pos']:
        if col not in df.columns:
            print(f"The required '{col}' column was not found. Please check the file format and header row.")
            sys.exit(1)

    # Define the required seasons.
    required_seasons = [2019, 2020, 2021, 2022, 2023, 2024]
    # Filter for rows with required seasons.
    relevant_df = df[df['Season'].isin(required_seasons)]
    if relevant_df.empty:
        print("Not enough Seasonal Data.")
        sys.exit(1)

    # Standardize positions in the relevant data.
    standardized_positions = relevant_df['Pos'].apply(standardize_position)
    unique_positions = standardized_positions.unique()

    # If more than one standardized position is found, error out.
    if len(unique_positions) > 1:
        print("Position changes, need further clarification")
        sys.exit(1)
    final_pos = unique_positions[0]
    print("Final standardized position:", final_pos)

    # Check that all required seasons are present.
    seasons_present = relevant_df['Season'].unique()
    if not all(year in seasons_present for year in required_seasons):
        print("Not enough Seasonal Data.")
        sys.exit(1)

    # For each required season, check at least one record has Games Played (G) > 6.
    for year in required_seasons:
        season_data = relevant_df[relevant_df['Season'] == year]
        if season_data['G'].max() < 6:
            print("Not enough games played in at least one Season.")
            sys.exit(1)

    # Define the mapping of positions to the columns (stats) to average.
    pos_columns = {
        "QB": ["Yds", "Cmp%", "Int", "TD", "1D"],
        "WR": ["Y/R", "Catch%", "Y/Tgt", "Succ%"],
        "RB": ["Y/A", "Y/R", "Succ%", "1D"],
        "TE": ["Y/R", "Catch%", "Y/Tgt", "Succ%"],
        "OL": ["Comb", "Solo", "Ast"],
        "DL": ["PD", "Comb", "Solo", "Ast"],
        "LB": ["PD", "Comb", "Solo", "Ast"],
        "CB": ["PD", "Comb", "Solo", "Ast"],
        "S": ["PD", "Comb", "Solo", "Ast"],
        "K": ["FG%", "Lng"],
        "P": ["Y/P", "Lng"]
    }

    # Ensure that final_pos is one of the keys we expect.
    if final_pos not in pos_columns:
        print(f"Position '{final_pos}' is not configured for selective stats averaging.")
        sys.exit(1)

    # Only average the specified columns for this position.
    columns_to_average = [col for col in pos_columns[final_pos] if col in df.columns]
    if not columns_to_average:
        print(f"None of the required columns for position '{final_pos}' were found in the file.")
        sys.exit(1)

    # Create groups for seasons 2019-2021 and 2022-2024 from the relevant data.
    group1 = relevant_df[relevant_df['Season'].isin([2019, 2020, 2021])]
    group2 = relevant_df[relevant_df['Season'].isin([2022, 2023, 2024])]

    # Calculate the averages for each group based only on the selected columns.
    avg_group1 = group1[columns_to_average].mean()
    avg_group2 = group2[columns_to_average].mean()
    diff = avg_group2 - avg_group1

    # Create a DataFrame with the averages and the difference.
    result_df = pd.DataFrame([avg_group1, avg_group2, diff],
                             index=["2019-2021", "2022-2024", "Difference"])

    # Determine the output folder: a subfolder in the input file's directory named after final_pos.
    input_dir = os.path.dirname(file_path)
    base_filename = os.path.splitext(os.path.basename(file_path))[0]
    pos_folder = os.path.join(input_dir, final_pos)
    if not os.path.exists(pos_folder):
        os.makedirs(pos_folder)

    # Output CSV file will be saved in that subfolder.
    output_filename = os.path.join(pos_folder, base_filename + ".csv")
    result_df.to_csv(output_filename, index=True, float_format="%.2f")
    print(f"CSV file created: {output_filename}")

if __name__ == "__main__":
    main()
