#!/usr/bin/env coffee

module.exports = assetLocation:
    javaScript: [
        'javaScript/jQuery/jquery-2.1.1.js'
        'javaScript/jQuery/jquery-observeHashChange-1.0.js'
        'javaScript/jQuery/jquery-scrollTo-2.1.0.js'
        'javaScript/jQuery/jquery-spin-2.0.1.js'
        '!**/node_modules/**', '!**/.*/**'
    ]
    coffeeScript: [
        'coffeeScript/jQuery/jquery-tools-1.0.coffee'
        'coffeeScript/jQuery/jquery-lang-1.0.coffee'
        'coffeeScript/jQuery/jquery-website-1.0.coffee'
        'coffeeScript/jQuery/jquery-documentation-1.0.coffee'
        'coffeeScript/main.coffee'
        '!**/node_modules/**', '!**/.*/**'
    ]
