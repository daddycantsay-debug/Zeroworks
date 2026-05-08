fx_version 'cerulean'
game 'gta5'

author 'zero-junkies'
description 'ESX & QBCore — Trap / Car Drug Selling Script'
version '2.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/store.html',
    'html/store.css',
    'html/store.js',
    'html/dialogue.html',
    'html/dialogue.css',
    'html/dialogue.js',
}

lua54 'yes'
