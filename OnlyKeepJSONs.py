#by Andrew Poženel#


import os
import send2trash

def delete_every_other_file(directory):
    """
    Deletes every other file in the specified directory, excluding files ending with ".json".

    Args:
        directory (str): The directory path.

    Returns:
        int: The number of files deleted.
    """
    deleted_count = 0

    try:
        for root, dirs, files in os.walk(directory):
            for file in files:
                file_path = os.path.join(root, file)
                if not file.endswith(".json"):
                    send2trash.send2trash(file_path)
                    deleted_count += 1
                    print(f"Deleted: {file_path}")  # Debug print to show deleted files
    except Exception as e:
        print(f"An error occurred: {e}")
    
    return deleted_count

if __name__ == "__main__":
    current_directory = os.getcwd()
    deleted_count = delete_every_other_file(current_directory)

    print(f"Number of files deleted: {deleted_count}")

    input("Press Enter to exit...")
