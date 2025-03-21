# Contribution guidance

## How to contribute

You can contribute in different ways:

- Report a bug in Issues
- Write a suggestion in Discussions
- Submit a modification to source code!

For the last one, you will need to download the Godot editor and obtain assets.
Read below to find out how to obtain assets.

## Editing the game in the Godot editor

First, obtain necessary files:

1. Download Godot editor *version 4.3* from the [Godot website](https://godotengine.org).
2. Clone the game repository using Git.
3. Download assets folder from this [Google Drive folder](https://drive.google.com/drive/folders/1U4wTjBu2qo1cInH3IAowsFC5yq56V5uQ?usp=sharing).
4. Copy and paste downloaded assets into 'assets' folder in the game repository.
5. You will see a popup asking whether you want to replace some files - press "Yes".

Then, follow these steps to correctly import assets into Godot editor:

1. Open the game project in the Godot editor.
2. Wait for Godot editor to import assets. Open the "Output" window to confirm that the process is finished. There will be some errors - that's expected.
3. Press Ctrl-S to save changes.
4. Close Godot editor
5. Open a terminal with Git and run this command: $ git status. You should see that some files were modified (by Godot editor).
6. Run this command: $ git restore
7. Open the game project in the Godot editor again.
8. Wait for Godot editor to import assets. This time, there should be no errors.
9. Run this command again: $ git status. There should be no local changes if steps were followed correctly.

Note: Public version of assets contains censored versions of item icons, tower icons and tower sprites. Such assets will look like they are a solid "blue" color.

## Copyright / Contributor License Agreement
Any code you submit will become part of the repository and be distributed under the YouTD2 license. By submitting code to the project you agree that the code is your work and you can give it to the project.

You also agree by submitting your code that you grant all transferrable rights to the code to the project maintainer, including for example re-licensing the code, modifying the code, and distributing it in source or binary forms. Specifically, this includes a requirement that you assign copyright to the project maintainer. For this reason, do not modify any copyright statements in files in any PRs.
