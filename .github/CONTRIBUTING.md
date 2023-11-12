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
