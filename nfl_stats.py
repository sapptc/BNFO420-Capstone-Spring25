import pandas as pd
import sys
import os
import glob
from openpyxl import load_workbook
from openpyxl.styles import PatternFill

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
    dl_set = {"DE", "DT", "NT", "LDT", "RDT", "LDE", "RDE"}
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

def process_file(file_path):
    """
    Process a single .xls file:
      - Extracts the player's name from the file name.
      - Reads the file and performs validations and standardization.
      - Computes selective stat averages and writes an individual CSV file.
      - Updates the aggregate Excel file for the player's standardized position.
    """
    try:
        # Ensure file_path is valid (.xls) and exists (should be guaranteed from caller)
        if not file_path.lower().endswith(".xls"):
            print(f"Skipping {file_path}: wrong format error.")
            return
        if not os.path.exists(file_path):
            print(f"Skipping {file_path}: file not found.")
            return

        # Extract the player's name from the file name (replace underscores with spaces)
        base_filename = os.path.splitext(os.path.basename(file_path))[0]
        player_name = base_filename.replace("_", " ").strip()
        print(f"\nProcessing player: {player_name}")

        # Read the .xls file with header on row 2.
        df = pd.read_excel(file_path, engine='xlrd', header=1)
        # Verify required columns exist.
        for col in ['Season', 'G', 'Pos']:
            if col not in df.columns:
                print(f"Skipping {file_path}: Required column '{col}' not found.")
                return

        # Define the required seasons.
        required_seasons = [2019, 2020, 2021, 2022, 2023, 2024]
        relevant_df = df[df['Season'].isin(required_seasons)]
        if relevant_df.empty:
            print(f"Skipping {file_path}: Not enough Seasonal Data.")
            return

        # Standardize positions in the relevant data.
        standardized_positions = relevant_df['Pos'].apply(standardize_position)
        unique_positions = standardized_positions.unique()
        if len(unique_positions) > 1:
            print(f"Skipping {file_path}: Position changes, need further clarification.")
            return
        final_pos = unique_positions[0]
        print(f"Standardized position: {final_pos}")

        # Check that all required seasons are present.
        seasons_present = relevant_df['Season'].unique()
        if not all(year in seasons_present for year in required_seasons):
            print(f"Skipping {file_path}: Not enough Seasonal Data.")
            return

        # Check that for each required season at least one record has G > 6.
        for year in required_seasons:
            season_data = relevant_df[relevant_df['Season'] == year]
            if season_data['G'].max() < 6:
                print(f"Skipping {file_path}: Not enough games played in season {year}.")
                return

        # Define mapping of positions to the columns (stats) to average.
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

        if final_pos not in pos_columns:
            print(f"Skipping {file_path}: Position '{final_pos}' is not configured for selective stats averaging.")
            return

        # Only average the specified columns for this position.
        columns_to_average = [col for col in pos_columns[final_pos] if col in df.columns]
        if not columns_to_average:
            print(f"Skipping {file_path}: None of the required columns for position '{final_pos}' were found.")
            return

        # Create groups for seasons 2019-2021 and 2022-2024.
        group1 = relevant_df[relevant_df['Season'].isin([2019, 2020, 2021])]
        group2 = relevant_df[relevant_df['Season'].isin([2022, 2023, 2024])]
        avg_group1 = group1[columns_to_average].mean()
        avg_group2 = group2[columns_to_average].mean()
        diff = avg_group2 - avg_group1

        # Create result DataFrame with 3 rows.
        result_df = pd.DataFrame([avg_group1, avg_group2, diff],
                                 index=["2019-2021", "2022-2024", "Difference"])
        result_df = result_df.reset_index().rename(columns={"index": "Season Group"})
        result_df.insert(0, "Player", player_name)

        # Determine output folder: subfolder in the folder containing the file named after final_pos.
        file_dir = os.path.dirname(file_path)
        pos_folder = os.path.join(file_dir, final_pos)
        if not os.path.exists(pos_folder):
            os.makedirs(pos_folder)

        # Write individual CSV file.
        output_filename = os.path.join(pos_folder, base_filename + ".csv")
        result_df.to_csv(output_filename, index=False, float_format="%.2f")
        print(f"Individual CSV created: {output_filename}")

        # Aggregate functionality:
        aggregate_filename = os.path.join(pos_folder, f"{final_pos}_aggregate.xlsx")
        if os.path.exists(aggregate_filename):
            try:
                aggregate_df = pd.read_excel(aggregate_filename)
            except Exception as e:
                print(f"Error reading aggregate file: {e}")
                aggregate_df = pd.DataFrame()
        else:
            aggregate_df = pd.DataFrame()

        # Check for duplicate player name in aggregate.
        skip_aggregate = False
        if not aggregate_df.empty and "Player" in aggregate_df.columns and player_name in aggregate_df["Player"].unique():
            while True:
                answer = input(f"Player '{player_name}' may already be added. If this is a new player with the same name, press Y. Otherwise, press N: ").strip().upper()
                if answer == "Y":
                    break
                elif answer == "N":
                    skip_aggregate = True
                    break
                else:
                    print("Invalid answer, please press Y or N.")

        if skip_aggregate:
            print("Aggregate update aborted for this player.")
        else:
            aggregate_df = pd.concat([aggregate_df, result_df], ignore_index=True)
            aggregate_df.to_excel(aggregate_filename, index=False)
            print(f"Aggregate Excel file updated: {aggregate_filename}")

            # Apply alternating row colors by entry (each player's entry = 3 rows).
            try:
                wb = load_workbook(aggregate_filename)
                ws = wb.active
                fill1 = PatternFill(start_color="CCFFCC", end_color="CCFFCC", fill_type="solid")  # Pale green
                fill2 = PatternFill(start_color="FFFFBD", end_color="FFFFBD", fill_type="solid")  # pale yellow
                # Data rows start at row 2.
                for row in range(2, ws.max_row + 1):
                    block_index = (row - 2) // 3
                    fill = fill1 if (block_index % 2 == 0) else fill2
                    for col in range(1, ws.max_column + 1):
                        ws.cell(row=row, column=col).fill = fill
                wb.save(aggregate_filename)
                print(f"Formatted aggregate Excel file saved: {aggregate_filename}")
            except Exception as e:
                print(f"Error applying formatting: {e}")
    except Exception as ex:
        print(f"An error occurred processing {file_path}: {ex}")

def main():
    # Prompt the user for the folder path containing .xls files.
    folder_path = input("Enter the full path to the folder containing .xls files: ").strip()
    folder_path = folder_path.strip('\'"')
    if not os.path.isdir(folder_path):
        print("Provided folder path does not exist or is not a directory.")
        sys.exit(1)

    # Use glob to list all .xls files in the folder.
    file_list = glob.glob(os.path.join(folder_path, "*.xls"))
    if not file_list:
        print("No .xls files found in the provided folder.")
        sys.exit(0)

    print(f"Found {len(file_list)} .xls file(s) in the folder.")

    # Process each file.
    for file_path in file_list:
        process_file(file_path)

if __name__ == "__main__":
    main()
