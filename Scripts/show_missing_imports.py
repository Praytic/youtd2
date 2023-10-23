import os
import sys

def print_usage():
    print("Usage: python find_pairs.py <directory_path> [--delete]")
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
if len(sys.argv) < 2 or len(sys.argv) > 3:
    print_usage()

# Starting directory
search_directory = sys.argv[1]

# Check for delete flag
delete_unmatched = False
if len(sys.argv) == 3:
    if sys.argv[2] == "--delete":
        delete_unmatched = True
    else:
        print_usage()

# Initialize lists to store all found files
files = []
import_files = []

# Walk through directory recursively
for dirpath, dirnames, filenames in os.walk(search_directory):
    for filename in filenames:
        if filename.endswith(tuple(file_extensions)):
            files.append(os.path.join(dirpath, filename))
        elif filename.endswith('.import') and any(filename.replace('.import', '').endswith(ext) for ext in file_extensions):
            import_files.append(os.path.join(dirpath, filename))

# Convert the main files list to their .import version for easy comparison
files_with_import = [f + ".import" for f in files]

# Find .import files that don't have a corresponding file
unmatched_import_files = set(import_files) - set(files_with_import)

if unmatched_import_files:
    print("Files with .import format but missing corresponding files:")
    for file in unmatched_import_files:
        print(file)
        if delete_unmatched:
            try:
                os.remove(file)
                print(f"Deleted: {file}")
            except Exception as e:
                print(f"Error deleting {file}: {e}")

print("\nFinished processing unmatched .import files.")
