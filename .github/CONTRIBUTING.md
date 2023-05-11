# Contribution guidance

## Assets

1. Install rclone from [here](https://rclone.org/downloads/).
2. Go to this [page](https://console.cloud.google.com/apis/credentials/oauthclient/909699965518-qt5c21qf6r7mr3rg26vkh6nml4s397e7.apps.googleusercontent.com?project=youtd2-385722). Copy and save `client_id` and `client_secret` to a text file. You will need them in the next step.
3. Follow the instructions [here](https://rclone.org/drive/) to configure `rcloud`. When prompted for `client_id` and `client_secret`, use the strings you have copied in the previous step.
4. Check that the remote is installed correctly. This command will print the installed `<remote>`.
```
rclone listremotes
```
5. This command should print the list of folders insides Assets in Google Drive.
```
rclone lsd <remote>:Assets
```
6. Transfer files to your local.
```
rclone sync --filter-from rclone-filter "<remote>:Assets" "Assets"
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
rclone copy -v --filter-from rclone-filter Assets <remote>:Assets
```

## Exporting models

1. To convert a 3D animated model into 2D spritesheet, you'll need to install [Blender](https://www.blender.org/download/).
2. Download "isometric-template.blend" from [here](https://drive.google.com/drive/folders/1AU0lNWg0xuZFsjmeP-DU5UQZHaXhlC2d). This is a prepared scene where camera has correct settings for isometric rendering.
3. Delete default cube and hide the floor plane. Impport an animated model into the scene. Switch to "Animation" tab. Make sure that the model fits within the rendering frame. If not, resize it.
4. Rename animation inside armature to one of the following (depending on the animation):
  - `run_slow`
  - `run_fast`
  - `stunned`
  - `death`
  - `floating`
5. Switch to "Scripting" tab. Open the latest [render_8_direction_sprites.py](https://github.com/Praytic/youtd2/blob/main/Scenes/render_8_direction_sprites.py) script. Run the script. Editor should lag if it's generating correctly.
6. Go to model's folder. There should be a "script-export" folder nearby. It will contain subfolders named after the animation actions. Find the action that you want to translate to sprites.
7. Download [Godot](https://godotengine.org/download) executable to the `<godot-path>`
8. Download [this](https://github.com/Praytic/youtd2/blob/main/Scenes/GenerateAtlas.gd) script which merges slides together into one sprite sheet to the `<generate-atlas-script-path>`
8. Run the following command to merge slides exported from the Blender:
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
9. Upload the sprite sheet, Blender project, fbx animations to the [Google Drive](https://drive.google.com/drive/folders/1AU0lNWg0xuZFsjmeP-DU5UQZHaXhlC2d). Keep file arrangement consistent, [example](https://drive.google.com/drive/folders/1zdILF_XKJu2Arkjpcb5bo8DTLln5YXf6).
10. Repeat for every model in the Drive:
- [ ] 'Human Archer - Proto Series'
- [ ] 'Human Knight - Proto Series'  
- [ ] 'Human Mage - Proto Series'
- [ ] 'Human Peasant - Proto Series'
- [ ] 'Human Soldier - Proto Series'
- [ ] orc-grunt-proto-series-v1
- [ ] orc-peon-proto-series
- [ ] orc-shaman-proto-series-v1
- [x] orc-warrior-proto-series-v1
- [ ] orc_chieftain_proto_series
- [ ] orc-archer-proto-series-v1
- [ ] elf_archer_v1
- [ ] elf_assassin_v1
- [ ] elven_priestess_v1
- [ ] elven_queen_v1
- [ ] elven_warrior_v1
- [ ] elven_worker_v1
