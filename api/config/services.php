<?php

return [
    'fcm' => [
        'server_key' => env('FCM_SERVER_KEY'),
        'transport' => env('PUSH_TRANSPORT', 'legacy'),
        'project_id' => env('FCM_PROJECT_ID'),
        'service_account_path' => env('FCM_SERVICE_ACCOUNT_PATH'),
    ],
];
