# Translation guidance

## How to contribute to translation

Translated text strings are stored in texts.csv. This file is not included on Github because it is too big.
Download link: [texts.csv](https://drive.google.com/file/d/1dfaUKx5CoU9oVQQ4DgFVJH_twJ7M5k4Q/view?usp=drive_link).

You can contribute translations like this:
1. Download the texts.csv file
2. Edit the texts.csv file
3. Create new column for your language, for example "es"
4. Add translated strings to that column

Then you can submit the changes like this:
1. Create a new Issue on Github
2. Attach changed texts.csv file to the Issue
3. Follow the format from here: https://github.com/Praytic/youtd2/issues/483

## How to add a new language

This section is intended for developers. If you only want to contribute new translation texts, you can skip this section and let someone else handle adding the new language.

1. Find the locale code here: https://docs.godotengine.org/en/stable/tutorials/i18n/locales.html
2. Create new column in texts.csv with locale code in first row.
3. Close texts.csv and open Godot editor, confirm in editor log that texts.csv was reloaded.
4. Go to Menubar -> Project -> Project Settings -> Localization -> Add. Then add the translation file.
5. Edit src/enums/language.gd. Add new language to the following: "enm", "language_map", "language_option_map", "language_option_locale_map"
6. Open settings_menu.tscn in editor and modify the language OptionButton. Add new language and use the same index as the one in language.gd.
7. Start the game and confirm that new language works.
