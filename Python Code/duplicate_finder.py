import os
import glob
import shutil

def move_duplicates(folder1, folder2):
    # Create the "Duplicates" folder inside folder2 if it doesn't exist
    duplicates_folder = os.path.join(folder2, "Duplicates")
    if not os.path.exists(duplicates_folder):
        os.makedirs(duplicates_folder)
    
    # Get a set of XLS file names (with extension) from folder1
    folder1_files = glob.glob(os.path.join(folder1, "*.xls"))
    folder1_names = {os.path.basename(f) for f in folder1_files}
    
    # Get a list of XLS files from folder2
    folder2_files = glob.glob(os.path.join(folder2, "*.xls"))
    
    # Check each file in folder2; if its name exists in folder1, it's considered a duplicate.
    duplicates = []
    for f in folder2_files:
        name = os.path.basename(f)
        if name in folder1_names:
            duplicates.append(f)
    
    # Move each duplicate file to the "Duplicates" folder
    for file_path in duplicates:
        dest_path = os.path.join(duplicates_folder, os.path.basename(file_path))
        try:
            shutil.move(file_path, dest_path)
            print(f"Moved duplicate: {os.path.basename(file_path)}")
        except Exception as e:
            print(f"Error moving file {file_path}: {e}")

if __name__ == "__main__":
    folder1 = input("Enter the path to folder 1: ").strip()
    folder2 = input("Enter the path to folder 2: ").strip()
    
    # Validate that both folders exist
    if not os.path.isdir(folder1):
        print("Folder 1 does not exist.")
        exit(1)
    if not os.path.isdir(folder2):
        print("Folder 2 does not exist.")
        exit(1)
    
    move_duplicates(folder1, folder2)
    print("Duplicate file processing complete.")
