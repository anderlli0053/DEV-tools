# by Andrew Poženel #


import os

def remove_duplicates_in_filename(path):
    """
    Remove files with duplicate names in the specified directory.
    
    Args:
        path (str): The directory path where duplicates should be removed.
        
    Raises:
        OSError: If an error occurs during file removal.
    """
    try:
        for filename in os.listdir(path):
            full_path = os.path.join(path, filename)
            if os.path.isfile(full_path):
                base_name, extension = os.path.splitext(filename)
                if "_(1)" in base_name or "_(1)_(1)" in base_name:
                    os.remove(full_path)
                    print(f"Deleted: {full_path}")
        print("Duplicates removal completed.")
    except OSError as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    current_path = os.getcwd()  # Get the current working directory
    try:
        remove_duplicates_in_filename(current_path)
    except KeyboardInterrupt:
        print("Operation aborted by user.")
    except Exception as e:
        print(f"An error occurred: {e}")
