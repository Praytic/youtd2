# TODO

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
