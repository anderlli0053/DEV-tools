# -----------------------------------------------------------------------------
# File: AnalyzeJSON.py
# Written by Andrew Pozenel 2023
# For more info visit: https://andrew-pozenel.xyz/
# -----------------------------------------------------------------------------


import json
import os

def load_json_file(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as json_file:
            data = json.load(json_file)
        return data
    except FileNotFoundError:
        print("File not found:", filename)
        return None
    except json.JSONDecodeError:
        print("Invalid JSON format in file:", filename)
        return None
    except Exception as e:
        print("An error occurred while loading the JSON file:", e)
        return None

def analyze_json_data(data):
    if not data:
        return

    if isinstance(data, list):
        print("Array of items:")
        for item in data:
            print(item)
    elif isinstance(data, dict):
        print("Dictionary keys:")
        for key in data:
            print(key)

        if 'items' in data and isinstance(data['items'], list):
            total_price = sum(item.get('price', 0) for item in data['items'])
            average_price = total_price / len(data['items'])
            print("Average price of items:", average_price)
    else:
        print("Unsupported JSON structure")

if __name__ == "__main__":
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        info_file_path = os.path.join(script_dir, "JSONINFO.json")
        
        analysis_results = []  # To store analysis results for all JSON files
        
        for filename in os.listdir(script_dir):
            if filename.endswith(".json"):
                json_data = load_json_file(filename)
                if json_data:
                    analysis_result = {"filename": filename, "content": json_data}
                    analyze_json_data(json_data)
                    analysis_results.append(analysis_result)
        
        with open(info_file_path, "w", encoding="utf-8") as info_file:
            json.dump(analysis_results, info_file, indent=4)
            
    except Exception as e:
        print("An error occurred:", e)