import os
import sys

def resolve_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    out = []
    lines = content.split('\n')
    i = 0
    while i < len(lines):
        if lines[i].startswith('<<<<<<< HEAD'):
            i += 1
            # inside HEAD
            head_lines = []
            while not lines[i].startswith('======='):
                head_lines.append(lines[i])
                i += 1
            i += 1 # skip =======
            main_lines = []
            while not lines[i].startswith('>>>>>>>'):
                main_lines.append(lines[i])
                i += 1
            i += 1 # skip >>>>>>>
            # Keep both
            out.extend(head_lines)
            out.extend(main_lines)
        else:
            out.append(lines[i])
            i += 1
            
    with open(filepath, 'w') as f:
        f.write('\n'.join(out))

for arg in sys.argv[1:]:
    resolve_file(arg)
