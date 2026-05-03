import os, sys, random, string, re

with open(".\\compiled\\release.luau", "r", encoding="utf-8") as f:
	script_data = f.read()

REPLACEMENTS = {
	"||RHEX5||": lambda: ''.join(random.choice(string.hexdigits).lower() for _ in range(5)),
	"--[[SCRIPTINS]]": lambda: script_data,
}

def process_file(file_path : str):
	with open(file_path, "r", encoding="utf-8") as file:
		content = file.read()

	for placeholder, replacement in REPLACEMENTS.items():
		if placeholder == "||RHEX5||":
			content = re.sub(re.escape(placeholder), lambda m: replacement(), content)
		else:
			content = content.replace(placeholder, replacement())

	with open('compiled/loader.luau', 'w', encoding='utf-8') as file:
		file.write(content)

if __name__ == "__main__":
	if len(sys.argv) < 2:
		print("Please provide a file path as an argument.")
		sys.exit(1)

	file_path = sys.argv[1]

	if not os.path.isfile(file_path):
		print(f"The file {file_path} does not exist.")
		sys.exit(1)

	process_file(file_path)
	print(f"Processed {file_path} and saved as {file_path[:-5]}_pre1.luau")


