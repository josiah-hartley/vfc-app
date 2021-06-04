# Voices for Christ

A mobile application built with Flutter to load and save messages from Voices for Christ.  Users can create playlists, mark favorites, and manage a queue.

## Important Packages

* Audio Service: [https://pub.dev/packages/audio_service](https://pub.dev/packages/audio_service)
  * Used with audio_session and just_audio, two related packages by the same developer
  * Wraps around audioplayer and allows for background listening, as well as communication with Bluetooth, notification controls, etc.
* Dio: [https://pub.dev/packages/dio](https://pub.dev/packages/dio)
  * Handles file downloads
* Scoped Model: [https://pub.dev/packages/scoped_model](https://pub.dev/packages/scoped_model)
  * Holds shared state across app
* Sliding Up Panel: [https://pub.dev/packages/sliding_up_panel](https://pub.dev/packages/sliding_up_panel)
  * Used for the player panel, which sits atop the scaffold and can be expanded or collapsed
* Sqflite: [https://pub.dev/packages/sqflite](https://pub.dev/packages/sqflite)
  * Holds data for the messages, playlists, etc. in a SQLite database

## Directory Structure
### data_models
Contains classes for Message, Playlist, Recommendation (category recommended by play history), and Download (holds progress and cancel token for active downloads)

### database
Handles SQLite database (see Database section below)

### files
Handles downloading and deleting mp3 files on device

## helpers
Helper functions, including:
* constants.dart: holds constant values like the max number of messages that can be selected at once
* device.dart: gets device data to include with error report
* duration_in_minutes.dart: converts the number of seconds in a message into a readable string of the form 'HH:MM:SS'
* featured_message_ids.dart: contains IDs for the featured messages (messages of the month on VFC)
* logger.dart: used for logging activity (submitted with error reports)
* minimize_keyboard.dart
* pause_reason.dart: when downloads are paused, this can be because of the user's choice, or because of the lack of connection
* playable_queue.dart: filters a queue down to the messages that can actually be played (the files exist on the device)
* reverse_speaker_name.dart
* toasts.dart: shows popups when needed

## player
Contains AudioHandler.dart, which defines the background audio task for audio_service

## scoped_models
App state

## screens
The MainScaffold class (in main_scaffold.dart) is the main entry point.  It has the following sections:
* The central screen, in which the Home, Favorites, Playlists, Downloads, and Settings pages are controlled by a Navigator
* The player sliding up panel
* A search panel, which is hidden off to the right of the screen when not in use (this way the search state is persisted)

## ui
Light and dark themes for the app

## widgets
Contains ActionButton class, as well as dialogs, components used to display message data in a list (MessageCard and related), the player view components, and search widgets

## Database
The app is shipped with an initial database (the messages loaded from voicesforchrist.net).  As more messages are added to the online database, the local copy would be out of date, so the app periodically checks for updates (with a manual option as well).

This database has 7 tables:
* downloads: persists download queue, so that if the app closes before downloads finish, the queue is reloaded on the next start
  * Fields: messageid (PK, INTEGER), initiated (INTEGER; time in millisecondsSinceEpoch)
* logs: user actions are logged for use with error reports
  * Fields: id (PK, INTEGER), timestamp (INTEGER; time in millisecondsSinceEpoch), type (TEXT; generally either 'action' or 'error'), text (TEXT)
* messages: core of the database, with the metadata for all the messages
  * id (INTEGER): message ID, the same one the website uses (PK)
  * created (INTEGER): date added to database
  * lastupdated (INTEGER): currently unused, could be handy if message data gets updated after creation
  * date (TEXT): the date (year) the message was given, if available
  * language (TEXT): the language, as listed on the website
  * speaker (TEXT): speaker name, in format Last, First
  * speakerurl (TEXT): currently unused, but contains link to website page for the speaker
  * taglist (TEXT): tags, in a comma-separated list
  * title (TEXT): title of the message
  * url (TEXT): the download link
  * filesize (TEXT): unused; this is an approximate value scraped from the website; utility seems limited
  * approximateminutes (INTEGER): scraped from the website; currently, the duration is calculated when the message is downloaded, so undownloaded messages have unknown length;  the website displays a length, but the value isn't trusted, so it's included as an approximation, only shown to the nearest minute
  * durationinseconds (REAL): when the message is downloaded, the duration is calculated and stored here
  * lastplayedposition (REAL): in seconds, the last position in this message (so that a user can pick up where they left off)
  * isdownloaded (INTEGER): boolean stored as integer
  * iscurrentlydownloading (INTEGER)
  * filepath (TEXT): location on local device where the file is saved (empty if it isn't downloaded, of course)
  * isfavorite (INTEGER): whether the user has marked this message as a favorite
  * isplayed (INTEGER): whether this message has already been played (used as a filter in many cases)
  * downloadedat (INTEGER): used to sort messages by download date
  * lastplayeddate (INTEGER): used to show user their listening history
* meta: contains metadata, including the last date the local database was synced with the online one and the total amount of storage used by the message mp3s
* mpjunction: used for the many-to-many relationship between messages and playlists
* playlists: contains data for playlists
  * Fields: id (INTEGER, PK), created (INTEGER), title (TEXT)
* recommendations: as users download and play messages, their recommendations are updated; this table holds that information
  * Recommendations are based on either a speaker or a tag
  * label (TEXT, PK): speaker name or tag text
  * type (TEXT): 'speaker' or 'tag'
  * count (INTEGER): the weight of this recommendation (more messages means a higher count, so it is listed higher in the recommended categories)