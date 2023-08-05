import os
import re

def remove_similar_duplicates(directory):
    try:
        file_list = os.listdir(directory)
        original_files = set()
        duplicates = []

        for filename in file_list:
            if os.path.isfile(os.path.join(directory, filename)):
                base_name, ext = os.path.splitext(filename)
                if not re.search(r"_\(\d+\)$", base_name):
                    original_files.add(filename)
                else:
                    duplicates.append(filename)

        removed_count = 0
        for duplicate in duplicates:
            os.remove(os.path.join(directory, duplicate))
            removed_count += 1
            print(f"Removed similar duplicate file: {duplicate}")

        print(f"Similar duplicate files removed.\nDuplicates found: {len(duplicates)}\nRemoved: {removed_count}")

    except Exception as e:
        print(f"Error: {str(e)}")

# Use the current working directory as the directory to remove similar duplicate files
current_directory = os.getcwd()

remove_similar_duplicates(current_directory)

# Input function to prevent console from closing immediately
input("Script execution complete. Press Enter to exit.")
