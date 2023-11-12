# Contribution guidance

## Assets

### Setup

Link to assets folder: [link](https://drive.google.com/drive/folders/1U4wTjBu2qo1cInH3IAowsFC5yq56V5uQ?usp=sharing)

(Note that these assets are partially replaced with placeholders)

1. Download the whole folder.
2. Copy the contents of the downloaded folder.
3. Paste into 'Assets' folder in the game repo.
4. You should see a popup asking whether you want to replace the files - press "Yes".
5. Open the Godot editor and make sure that all of the Assets were loaded correctly.

### Setup with rclone

You can use the rclone tool to automatically sync your local assets folder with the remote assets folder.

1. Install rclone from [here](https://rclone.org/downloads/).
2. Go to this [page](https://console.cloud.google.com/apis/credentials/oauthclient/909699965518-qt5c21qf6r7mr3rg26vkh6nml4s397e7.apps.googleusercontent.com?project=youtd2-385722). Copy and save `client_id` and `client_secret` to a text file. You will need them in the next step.
3. Follow the instructions [here](https://rclone.org/drive/) to configure `rcloud`. When prompted for `client_id` and `client_secret`, use the strings you have copied in the previous step.
4. Check that the remote is installed correctly. This command will print the installed `<remote>`.
```
rclone listremotes
```
5. This command should print the list of folders insides Assets in Google Drive.
```
rclone lsd <remote>:Assets_public
```
6. Transfer files to your local.
```
rclone sync -P --filter-from rclone-filter "<remote>:Assets_public" "Assets"
```

Now you should be able to run the project inside the Godot editor. If you make changes to a file inside Assets folder, make sure to update Google Drive as well. There are two options.

**First option - Google Drive upload.**

1. Upload a file to [Google Drive](https://drive.google.com/drive/u/1/folders/1V9GN1uoX9-mu2J5IoWPaNJU2aC_ejGIA)
2. Run `rclone sync`
3. Generate `.import` by opening the file in the editor
4. Commit `.import` file to remote

**Second option - rclone copy.**
1. Move a file to `Assets` folder
2. Generate `.import` by opening the file in the editor
3. Commit `.import` file to remote
4. Upload the file to <remote>.
```
rclone copy -v --filter-from rclone-filter Assets <remote>:Assets_public
```

### Exporting models

1. To convert a 3D animated model into a 2D sprite sheet, you need to install [Blender](https://www.blender.org/download/).
2. Download the "isometric-template.blend" from [here](https://drive.google.com/drive/folders/1AU0lNWg0xuZFsjmeP-DU5UQZHaXhlC2d). This is a prepared scene where the camera has the correct settings for isometric rendering.
3. Delete the default cube and hide the floor plane. Import an animated model into the scene. Switch to the "Animation" tab. Ensure that the model fits within the rendering frame. If not, resize it. Don't forget to import weapons and attach them to the armature.
4. Rename the animation inside the armature to one of the following, depending on the animation:
    - `run_slow`
    - `run_fast`
    - `stunned`
    - `death`
    - `floating`
5. Switch to the "Scripting" tab. Open the latest [render_8_direction_sprites.py](https://github.com/Praytic/youtd2/blob/main/Scenes/render_8_direction_sprites.py) script. Run the script. The editor should lag if it's generating correctly.
6. Go to the model's folder. There should be a "script-export" folder nearby. It will contain subfolders named after the animation actions. Find the action that you want to translate into sprites.
7. Download [Godot](https://godotengine.org/download) executable to the `<godot-path>`
8. Download [this](https://github.com/Praytic/youtd2/blob/main/Scenes/GenerateAtlas.gd) script which merges slides together into one sprite sheet to the `<generate-atlas-script-path>`
9. Run the following command to merge slides exported from the Blender:
    ```
    <godot-path>/<godot-console-executable> -s "<generate-atlas-script-path>" --path="<export-path>" --name="<unit-type>_<animation-name>"
    ```
    So, for example, on Windows the command should look like this:
    ```
    C:/Users/user/Downloads/godot/Godot_v4.0.2-stable_win64.exe -s "C:\Users\user\Downloads\youtd2\Scenes\GenerateAtlas.gd" --path="run_slow" --name="orc-normal_run-slow"
    ```
    You should see:
    ```
    GenerateAtlas.gd begin
    GenerateAtlas.gd end
    ```
    And the end result is a folder "generated-atlases" with sprite sheets in the folder where you executed the script.
  
10. Upload the sprite sheet, Blender project, FBX animations to the [Google Drive](https://drive.google.com/drive/folders/1AU0lNWg0xuZFsjmeP-DU5UQZHaXhlC2d). Keep file arrangement consistent, [example](https://drive.google.com/drive/folders/1zdILF_XKJu2Arkjpcb5bo8DTLln5YXf6).
