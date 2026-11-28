import json
import sys

metadata_path = sys.argv[1]

with open(metadata_path, "r") as f:
    data = json.load(f)

data["session-modes"] = ["user", "unlock-dialog"]

with open(metadata_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
