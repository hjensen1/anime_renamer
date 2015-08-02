# anime_renamer
Renames anime files to include episode names.

Data is pulled from page source on animenewsnetwork.com

Usage
---
input.txt should contain the root directory of folders to be modified. Paths of folders to rename will be interpreted relative to this path.

Upon starting the program, you are presented with a prompt. Here you can change options or enter the name of a folder to rename.

Current commands:
  'titles' - Changes renaming mode. Will attempt to find titles online and rename episodes accordingly.
    If there are episodes without titles found, it will rename them in 'numbers' mode. (This is the default mode)
  'titles only' - Changes renaming mode. Same as titles, but will not rename any episodes whose titles it can't find.
    This is useful if the series is divided into multiple parts on ANN.
  'numbers' - Changes renaming mode. Will rename the files based on the name of the containing folder and the episode number.
  'quit' or 'exit' - ends the program
  'cd <dir>' - changes the current directory which all renaming directories will be evaluated relative.
  'ls' - lists the contents of the current working directory
  'mv <file>' - moves/renames a file manually. You will receive a second prompt asking where to move the file to.
  Anything that is not recognize as one of these commands will be interpreted as a directory of anime files to be renamed.
  This can be either an exact path or relative to the current working directory.

Renaming Process
---
Once a valid folder name has been entered, the renamer will look for the episode number in the filename of each file in the folder.
Sub-directories are ignored in this process. Contents of file names which are not numbers are ignored.

If multiple numbers are found in a file name, or no number is found, you will be asked to enter the episode number.
Entering 'ignore' when prompted here will cause the program to not rename the file.

Once each file has a single number, it will check for duplicate numbers between the files. You will be asked to specify the number/name for
each of these files. Note that your input need not necessarily be a number, and you can specify 'ignore' in this step as well.
This step will repeat until there are no episodes with the same number.

At this point, if set in numbers mode, it will simply rename the episodes to "<folder name> <episode number/name>.<extension>"

If in titles mode, it will search for the series on ANN. If the search returns multiple options, it will provide a list of the options
and ask for you to input the number of the correct option. It will then extract the episode titles from the relevant page and rename the files
to "<episode number> - <title>.<extension>".