import json
import sys
import os

def search_json(data, target_key, current_path=""):
    """
    Recursively searches for a key and builds the full path.
    """
    # If the current data is a dictionary
    if isinstance(data, dict):
        for key, value in data.items():
            # Construct the new path string
            new_path = f"{current_path} -> {key}" if current_path else key
            
            # Check if this key matches our target
            if key == target_key:
                print(f"MATCH FOUND:")
                print(f"  Path:  {new_path}")
                print(f"  Value: {value}\n")
            
            # Continue searching deeper into the value
            search_json(value, target_key, new_path)
            
    # If the current data is a list, check each element
    elif isinstance(data, list):
        for index, item in enumerate(data):
            # We add the index to the path to stay accurate
            new_path = f"{current_path}[{index}]"
            search_json(item, target_key, new_path)

def main():
    # We need exactly 3 arguments: script name, filename, and target key
    if len(sys.argv) != 3:
        print("Usage: python script_name.py <filename.json> <search_key>")
        return

    filename = sys.argv[1]
    target_key = sys.argv[2]

    if not os.path.exists(filename):
        print(f"Error: File '{filename}' not found.")
        return

    try:
        with open(filename, 'r') as file:
            data = json.load(file)
            print(f"Searching for key '{target_key}' in '{filename}'...\n")
            search_json(data, target_key)
            
    except json.JSONDecodeError:
        print("Error: Invalid JSON format.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    main()
