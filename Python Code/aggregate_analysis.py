import os
import glob
import pandas as pd

def process_aggregate_file(filepath):
    # Read with no header so we can grab the real header row ourselves
    df_raw = pd.read_excel(filepath, header=None)
    # First row is the header
    header = df_raw.iloc[0].tolist()
    df = df_raw.iloc[1:].copy()
    df.columns = header

    # Identify stat columns (everything except Player and Season Group)
    stats_cols = [c for c in df.columns if c not in ('Player', 'Season Group')]

    # Count unique players
    num_players = df['Player'].nunique()

    # Select only the "Difference" rows
    df_diff = df[df['Season Group'].astype(str).str.lower() == 'difference'].copy()

    # Clean & convert stat columns to floats (strip '%' if present)
    for col in stats_cols:
        df_diff[col] = (
            df_diff[col]
            .astype(str)
            .str.rstrip('%')         # remove trailing percent sign
            .replace('nan', '')      # drop literal 'nan'
            .astype(float)
        )

    # Compute averages
    avg_per_stat = df_diff[stats_cols].mean()
    overall_avg = df_diff[stats_cols].values.flatten().mean()

    return num_players, avg_per_stat, overall_avg

def main():
    folder = input("Enter the folder path containing aggregate files: ").strip()
    pattern = os.path.join(folder, '*_aggregate.xlsx')
    files = glob.glob(pattern)

    summary = []

    for fp in files:
        pos = os.path.splitext(os.path.basename(fp))[0].replace('_aggregate', '')
        try:
            n_players, avg_stats, overall = process_aggregate_file(fp)
        except Exception as e:
            print(f"❗ Error processing {fp}: {e}")
            continue

        # Print per‐file results
        print(f"\n=== Position: {pos} ===")
        print(f"Players: {n_players}")
        print("Avg %‑diff by stat:")
        for stat, val in avg_stats.items():
            print(f"  {stat}: {val:.4f}")
        print(f"Overall avg %‑diff: {overall:.4f}")

        summary.append({
            'Position': pos,
            'NumPlayers': n_players,
            **{f'AvgDiff_{stat}': avg for stat, avg in avg_stats.items()},
            'OverallAvgDiff': overall
        })

    # Build ranking DataFrame
    rank_df = pd.DataFrame(summary).sort_values('OverallAvgDiff', ascending=False)

    # Print ranking
    print("\n=== Positions Ranked (by overall avg %‑diff desc) ===")
    for i, row in enumerate(rank_df.itertuples(index=False), 1):
        print(f"{i}. {row.Position} — {row.OverallAvgDiff:.4f}")

    # Save to CSV
    out_csv = os.path.join(folder, 'Ranked Averages.csv')
    rank_df.to_csv(out_csv, index=False)
    print(f"\n✅ Saved ranking to: {out_csv}")

if __name__ == '__main__':
    main()
