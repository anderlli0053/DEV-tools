#by Andrew Poženel#

import os
import shutil
from tqdm import tqdm

def copy_json_files():
    """
    Copy JSON files from the current directory and its subdirectories to a folder named 'JSONS'.
    
    This function performs the following steps:
    1. Search for JSON files in the current directory and its subdirectories.
    2. Create a folder named 'JSONS' if it doesn't exist.
    3. Copy the JSON files to the 'JSONS' folder with a progress bar.
    """
    try:
        # Define the root directory to search for JSON files
        root_directory = os.getcwd()

        # Create the JSONS folder if it doesn't exist
        jsons_folder = os.path.join(root_directory, "JSONS")
        os.makedirs(jsons_folder, exist_ok=True)

        # Search for JSON files in subdirectories
        json_files = []
        for root, dirs, files in os.walk(root_directory):
            for file in files:
                if file.endswith(".json"):
                    json_files.append(os.path.join(root, file))

        # Count the number of JSON files found
        json_count = len(json_files)
        print(f"Number of JSON files found: {json_count}")

        # Copy the JSON files to the JSONS folder with a progress bar
        print("Copying JSON files...")
        for json_file in tqdm(json_files, desc="Progress", unit="file"):
            file_name = os.path.basename(json_file)
            destination = os.path.join(jsons_folder, file_name)

            # Handle filename conflicts
            counter = 1
            while os.path.exists(destination):
                file_name, extension = os.path.splitext(file_name)
                new_file_name = f"{file_name}_({counter}){extension}"
                destination = os.path.join(jsons_folder, new_file_name)
                counter += 1

            shutil.copy2(json_file, destination)

        # Print the path of the JSONS folder
        print(f"JSON files copied to: {jsons_folder}")

    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    copy_json_files()
