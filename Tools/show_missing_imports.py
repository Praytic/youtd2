import os
import sys

def print_usage():
    print("Usage: python find_pairs.py <directory_path> [--delete] [--used]")
    sys.exit(1)

# Supported file extensions
file_extensions = [
    # Archives
    ".7z", ".br", ".gz", ".tar", ".zip",
    
    # Documents
    ".pdf",
    
    # Images
    ".gif", ".ico", ".jpg", ".png", ".psd", ".webp",
    
    # Fonts
    ".woff2", ".otf",
    
    # Audio
    ".mp3", ".wav",
    
    # Other
    ".exe"
]

# Check arguments
if len(sys.argv) < 2:
    print_usage()

# Starting directory
search_directory = sys.argv[1]

# Check for delete and used flags
delete_unmatched = "--delete" in sys.argv
used_only = "--used" in sys.argv

# Initialize lists to store all found files
files = []
import_files = {}
text_files = {}

# Walk through directory recursively
for dirpath, dirnames, filenames in os.walk(search_directory):
    for filename in filenames:
        full_path = os.path.join(dirpath, filename)
        if filename.endswith(tuple(file_extensions)):
            files.append(full_path)
        elif filename.endswith('.import') and any(filename.replace('.import', '').endswith(ext) for ext in file_extensions):
            import_files[os.path.basename(full_path).replace('.import', '')] = full_path
        elif filename.endswith(('.tscn', '.gd')):
            with open(full_path, 'r', encoding="utf-8", errors="ignore") as f:
                content = f.read()
                text_files[full_path] = content

# Convert the main files list to their .import version for easy comparison
files_with_import = [f + ".import" for f in files]

# Find .import files that don't have a corresponding file
unmatched_import_files = set(import_files.values()) - set(files_with_import)

if unmatched_import_files:
    print("Files with .import format but missing corresponding files:")
    for file in unmatched_import_files:
        base_name = os.path.basename(file).replace('.import', '')
        print(file)
        if used_only:
            mentioned_in = [path for path, content in text_files.items() if base_name in content]
            if mentioned_in:
                print(f"  Mentioned in:")
                for m in mentioned_in:
                    print(f"    {m}")
            else:
                continue  # Skip to next iteration if the missing file is not mentioned
        if delete_unmatched:
            try:
                os.remove(file)
                print(f"  Deleted: {file}")
            except Exception as e:
                print(f"  Error deleting {file}: {e}")
        print("")

print("\nFinished processing unmatched .import files.")
