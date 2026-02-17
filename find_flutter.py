
import os
import sys

print("Searching for flutter...")

search_locations = [
    # C Drive Common
    r"C:\flutter\bin",
    r"C:\src\flutter\bin",
    r"C:\Program Files\flutter\bin",
    r"C:\Users\Merve TOPALOĞLU\flutter\bin",
    r"C:\Users\Merve TOPALOĞLU\AppData\Local\flutter\bin",
    r"C:\Users\Merve TOPALOĞLU\AppData\Local\Android\flutter\bin",
    r"C:\Users\Merve TOPALOĞLU\Documents\flutter\bin",
    r"C:\Users\Merve TOPALOĞLU\Downloads\flutter\bin",
    r"C:\Users\Public\flutter\bin",
    
    # D Drive Common
    r"D:\flutter\bin",
    r"D:\src\flutter\bin",
    r"D:\Program Files\flutter\bin",
    r"D:\Users\Merve TOPALOĞLU\flutter\bin",
    r"D:\Users\Merve TOPALOĞLU\Documents\flutter\bin",
    r"D:\Users\Merve TOPALOĞLU\Downloads\flutter\bin",
    
    # Add other drives if needed
]

found_path = None

def check_path(path):
    bat_path = os.path.join(path, "flutter.bat")
    if os.path.exists(bat_path):
        return path
    return None

# Check specific locations first (fast)
for loc in search_locations:
    if check_path(loc):
        found_path = loc
        break

if not found_path:
    print("Fast search failed. Attempting deep search on D: drive...")
    # Walk D: drive looking for flutter/bin/flutter.bat
    # We avoid C: deep search here because it's huge, but D: is specific usually
    for root, dirs, files in os.walk("D:\\"):
        if "flutter.bat" in files:
            if root.endswith("bin"):
                found_path = root
                break
        # Optional: Skip system dirs to speed up
        if "$RECYCLE.BIN" in dirs:
            dirs.remove("$RECYCLE.BIN")
        if "System Volume Information" in dirs:
            dirs.remove("System Volume Information")

if not found_path:
    print("Deep search D: failed. Attempting deep search on C: drive users...")
    # Walk C:\Users looking for flutter/bin/flutter.bat
    for root, dirs, files in os.walk("C:\\Users"):
         if "flutter.bat" in files:
            if root.endswith("bin"):
                found_path = root
                break

if found_path:
    print(f"FOUND: {found_path}")
    with open("flutter_path.cfg", "w", encoding="utf-8") as f:
        f.write(found_path)
else:
    print("NOT FOUND in reasonable locations.")
