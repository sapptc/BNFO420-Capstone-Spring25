# NFL Stats Processing Script

### Overview
This repo contains a Python script designed to process NFL player statistics from Excel files, a python script that finds and removes duplicates, and others that aggregate date in different ways. The script reads player stats, validates the data, standardizes position names, calculates averages for different seasons, and outputs the results into organized CSV files.

## All Stats Folders
There are multiple different folders organizing the run statistics for each player in various ways. Some are COVID-19 specific, some are by position, and some are by player. SOme are just combined aggregates. You'll find percentage based difference and integer based differences.

- **Naming the File:**
    For this to work well and properly, you'll get a Microsoft Excel export from <https://www.pro-football-reference.com/> for the player you desire to get stat averages on. Before inputting this file through the program you **MUST** open the file and 'Save As...' a 'Excel 97 - 2003' file type .xsl. 
    The default way the .xsl comes from the website is formatted in an embedded html format that makes it unreadable by the program, so just save it as instructed above first.

- **File Input:**  
  Prompts the user to enter the full file path of a `.xls` file. The script automatically strips any extra quotes (e.g., when using "Copy as Path").

- **Header Parsing:**  
  Reads the Excel file assuming the column headers are on the second row (i.e., row index 1).

- **Data Validation:**  
  Verifies that the file contains required columns (`Season`, `G`, and `Pos`), ensures that data is present for seasons 2019 to 2024, and confirms that for each season at least one record has at least 6 games played.

- **Position Standardization:**  
  Standardizes the position values using predefined mappings. For example:
  - **Offensive Line:** `OT`, `OG`, `G`, `C` → `OL`
  - **Defensive Line:** `DE`, `DT`, `NT` → `DL`
  - **Linebackers:** Variants like `LB`, `OLB`, `ILB`, `MLB`, `WLB`, `WILL`, `SLB`, `SAM` → `LB`
  - **Cornerbacks:** `CB`, `NC`, `NCB`, `DC`, `DCB`, `DB` → `CB`
  - **Safeties:** `FS`, `SS` → `S`
  - **Returners:** `RET`, `KR`, `PR` → `RET`

- **Selective Stat Averaging:**  
  Based on the standardized position, only the relevant stats are averaged:
  - **QB:** `Yds`, `Cmp%`, `Int`, `TD`, `1D`
  - **WR:** `Y/R`, `Catch%`, `Y/Tgt`, `Succ%`
  - **RB:** `Y/A`, `Y/R`, `Succ%`, `1D`
  - **TE:** `Y/R`, `Catch%`, `Y/Tgt`, `Succ%`
  - **OL:** `Comb`, `Solo`, `Ast`
  - **DL:** `PD`, `Comb`, `Solo`, `Ast`
  - **LB:** `PD`, `Comb`, `Solo`, `Ast`
  - **CB:** `PD`, `Comb`, `Solo`, `Ast`
  - **S:** `PD`, `Comb`, `Solo`, `Ast`
  - **K:** `FG%`, `Lng`
  - **P:** `Y/P`, `Lng`

- **Season Grouping & Calculation:**  
  The script divides the data into two groups:
  - **Group 1:** Seasons 2019–2021  
  - **Group 2:** Seasons 2022–2024  
  It calculates the average for each group and then computes the difference (Group 2 average minus Group 1 average) for the selected stats.

- **Output:**  
  The CSV file is saved in a subfolder named after the standardized position (e.g., `WR`) within the same directory as the input file. The CSV file's name mirrors the input file's name (with a `.csv` extension).

## Using in VS Code and within the Repository
Cloning this in your workspace will provide all the position folder you should need as well as any player stats that have already been uploaded. 

### Prerequisites

- **Python 3.x**
- **Required Packages:**  
  Install the necessary packages using pip:
  ```bash
  pip install -r requirements.txt
  ```
- **Pandas**: For data manipulation and analysis.
- **NumPy**: For numerical operations.
- **OpenPyXL**: For reading Excel files.
- **XLRD**: For reading `.xls` files.
