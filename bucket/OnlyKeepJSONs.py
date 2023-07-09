import os
import send2trash

def delete_every_other_file(directory):
    deleted_count = 0

    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            if not file.endswith(".json"):
                send2trash.send2trash(file_path)
                deleted_count += 1

    return deleted_count

current_directory = os.getcwd()
deleted_count = delete_every_other_file(current_directory)

print(f"Number of files deleted: {deleted_count}")

input("Press Enter to exit...")
