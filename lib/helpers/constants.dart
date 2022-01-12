// don't allow more than this many messages to be selected in a results list
const int QUEUE_PLAYLIST_ID = 0;
const int QUEUE_BACKLOG_SIZE = 5; // number of played messages to keep in the queue
const double COLLAPSED_PLAYBAR_HEIGHT = 75.0;
const double EXPANDED_PLAYBAR_TOP_PADDING = 120.0;
const double MAX_EXPANDED_PLAYBAR_HEIGHT = 700.0;
const double MAX_RECOMMENDATION_WIDTH = 300.0;
const int MESSAGE_SELECTION_LIMIT = 25;
const int MESSAGE_LOADING_BATCH_SIZE = 50; // should be an even number
const int ACTIVE_DOWNLOAD_QUEUE_SIZE = 5;
const String CLOUD_DATABASE_BASE_URL = 'https://us-central1-voices-for-christ.cloudfunctions.net/getMessagesSinceDate';
const String CLOUD_ERROR_REPORT_URL = 'https://us-central1-voices-for-christ.cloudfunctions.net/postErrorReport';
const int DAYS_TO_MANUALLY_CHECK_CLOUD = 7; // only let manual updates happen once a week
const int DAYS_TO_AUTOMATICALLY_CHECK_CLOUD = 30; // do automatic checks monthly
const int LOGS_TO_KEEP_IN_DB = 100;
const String APP_VERSION = '1.0.16+23';