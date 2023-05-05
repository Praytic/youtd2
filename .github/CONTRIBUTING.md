# TODO

## Assets

1. [Follow the instructions](https://rclone.org/drive/) on how to setup `rcloud` command line utility with Google Drive support.
2. When you're prompted to write `client_id` and `client_secret`, use the ones from [Google Cloud console](https://console.cloud.google.com/apis/credentials/oauthclient/909699965518-qt5c21qf6r7mr3rg26vkh6nml4s397e7.apps.googleusercontent.com?project=youtd2-385722).
3. Check that the remote is installed correctly. This command will print the installed _<remote>_.
```
rclone listremotes
```
4. This command should print the list of folders insides Assets in Google Drive.
```
rclone lsd <remote>:Assets
```
5. Transfer files to your local.
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
4. Run 
```
rclone copy -v --filter-from rclone-filter Assets gdrive:Assets
```
