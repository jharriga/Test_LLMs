import json
import sys
import os
import matplotlib.pyplot as plt
from datetime import datetime

"""The JSON Path Grapher with Annotations"""

def get_nested_value(data, path_list):
    """Recursively follows a list of keys (JSON Path) to find a value."""
    if not path_list or data is None:
        return data
    
    key = path_list[0]
    
    if "[" in key and "]" in key:
        try:
            name = key.split("[")[0]
            index = int(key.split("[")[1].split("]")[0])
            target = data[name] if name else data
            if isinstance(target, list) and index < len(target):
                return get_nested_value(target[index], path_list[1:])
        except (IndexError, ValueError, KeyError, TypeError):
            return None
    
    if isinstance(data, dict) and key in data:
        return get_nested_value(data[key], path_list[1:])
    
    return None

def parse_timestamp(ts_raw):
    """Converts Linux Epoch or ISO strings into a datetime object."""
    if ts_raw is None:
        return None
    try:
        ts_float = float(ts_raw)
        if ts_float > 1e11: 
            ts_float /= 1000
        return datetime.fromtimestamp(ts_float)
    except (ValueError, TypeError):
        try:
            return datetime.fromisoformat(str(ts_raw).replace('Z', '+00:00'))
        except (ValueError, TypeError):
            return None

def main():
    if len(sys.argv) < 4:
        print("Usage: python script.py <file.json> <timestamp_path> <metric_path>")
        return

    filename = sys.argv[1]
    time_path_str = sys.argv[2]
    metric_path_str = sys.argv[3]
    
    time_path = time_path_str.split('.')
    metric_path = metric_path_str.split('.')

    if not os.path.exists(filename):
        print(f"Error: {filename} not found.")
        return

    x_values, y_values = [], []

    try:
        with open(filename, 'r') as f:
            data_store = json.load(f)
            records = data_store if isinstance(data_store, list) else [data_store]

            for record in records:
                raw_ts = get_nested_value(record, time_path)
                if raw_ts is None:
                    continue

                dt = parse_timestamp(raw_ts)
                raw_val = get_nested_value(record, metric_path)
                
                if dt is not None and raw_val is not None:
                    try:
                        x_values.append(dt)
                        y_values.append(float(raw_val))
                    except ValueError:
                        continue

        if not x_values:
            print("No valid data points found.")
            return

        # Sort chronologically
        sorted_data = sorted(zip(x_values, y_values))
        x_plot, y_plot = zip(*sorted_data)

        # Rendering
        plt.figure(figsize=(14, 7))
        plt.plot(x_plot, y_plot, marker='o', markersize=5, linestyle='-', color='#2c3e50', alpha=0.7)
        
        # --- NEW: ADD ANNOTATIONS ---
        for x, y in zip(x_plot, y_plot):
            label = f"{y:g}"  # ':g' removes unnecessary trailing zeros
            plt.annotate(label, 
                         (x, y), 
                         textcoords="offset points", 
                         xytext=(0, 10),      # Position 10 points above the marker
                         ha='center',         # Horizontally centered
                         fontsize=9,
                         fontweight='bold',
                         color='#e74c3c')     # Red color for visibility

        plt.title(f"Annotated Trend: {metric_path_str}", fontsize=14)
        plt.xlabel(f"Time ({time_path_str})")
        plt.ylabel("Value")
        plt.grid(True, linestyle=':', alpha=0.5)
        plt.xticks(rotation=45)
        
        # Adjust y-axis slightly so top labels aren't cut off
        y_min, y_max = plt.ylim()
        plt.ylim(y_min, y_max * 1.1)
        
        plt.tight_layout()

        output_filename = f"{metric_path_str.replace('.', '_')}_annotated.png"
        plt.savefig(output_filename, dpi=300)
        print(f"Success! Annotated plot saved as: {output_filename}")
        plt.show()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()

