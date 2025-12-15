import re

nums = [6, 7, 8]

def replace_words_in_file(input_file, output_file, replacements):
    with open(input_file, 'r') as file:
        content = file.read()
    
    for word, replacement in replacements.items():
        content = re.sub(rf'\b{word}\b', replacement, content)
    
    with open(output_file, 'w') as file:
        file.write(content)

for num in nums:
    print(num)
    # Define the replacements
    replacements = {
        "Eno4": f"Eno{num}",
        "Ene4": f"Ene{num}",
        "comp4": f"comp{num}",
        "conn4": f"conn{num}",
        "proj4": f"proj{num}",
        "comp4l": f"comp{num}l",
        "conn4l": f"conn{num}l",
        "proj4l": f"proj{num}l",
        "comp4u": f"comp{num}u",
        "conn4u": f"conn{num}u",
        "proj4u": f"proj{num}u",
    }
    
    # Example usage
    input_file = 'auto4.txt'  # replace with your input file name
    output_file = f'auto{num}.txt'  # replace with your desired output file name

    replace_words_in_file(input_file, output_file, replacements)