import os
import hashlib
import argparse

def get_file_content(file_path):
    with open(file_path, 'r', encoding='utf-8-sig') as file:
        content = parse_json_like(file.read())
    return content

def parse_json_like(json_like_string):
    content = {}
    lines = json_like_string.split('\n')
    for line in lines:
        line = line.strip()
        if line:
            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip().strip("'")
                value = value.strip().strip("'")
                content[key] = value
    return content

def get_file_hash(file_path):
    content = get_file_content(file_path)
    content_hash = hashlib.sha256(str(content).encode('utf-8')).hexdigest()
    return content_hash

def remove_duplicates(directory):
    file_hashes = {}
    duplicates = []

    for file_name in os.listdir(directory):
        if file_name.endswith('.json'):
            file_path = os.path.join(directory, file_name)
            file_hash = get_file_hash(file_path)

            if file_hash in file_hashes:
                duplicates.append(file_path)
            else:
                file_hashes[file_hash] = file_path

    removed_count = 0
    for duplicate_file in duplicates:
        try:
            os.remove(duplicate_file)
            removed_count += 1
        except OSError as e:
            print(f"Error removing file: {duplicate_file}\n{e}")

    num_duplicates_found = len(duplicates)
    print(f"Found {num_duplicates_found} duplicate files.")
    print(f"Removed {removed_count} duplicate files.")

def main():
    parser = argparse.ArgumentParser(description='Duplicate File Remover')
    parser.add_argument('directory', help='Directory path')
    args = parser.parse_args()

    try:
        remove_duplicates(args.directory)
    except FileNotFoundError:
        print(f"Directory not found: {args.directory}")
    except Exception as e:
        print(f"An error occurred:\n{e}")

if __name__ == '__main__':
    main()
