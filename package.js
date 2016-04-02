Package.describe({
    name: 'alino:mongo2es',
    summary: 'create hooks for MongoDB collection to sync with ElasticSearch',
    version: '0.0.6',
    git: 'https://github.com/Alino/alino-mongo2es.git'
});

Package.onUse(function (api) {
    api.versionsFrom(['METEOR@1.2']);

    var packages = [
        "mongo@1.1.2",
        "http@1.1.1",
        "coffeescript",
        "underscore",
        "alino:logit@0.0.3"
    ];

    api.use(packages);

    api.addFiles([
        "lib/mongo2es.coffee",
        "lib/init.coffee",
        "lib/export.js"
    ], 'server');

    api.export('Mongo2ES', 'server');

});

Package.onTest(function(api) {
    api.versionsFrom("METEOR@1.2");
    api.use([
        "mongo@1.1.2",
        "http@1.1.1",
        'coffeescript',
        'underscore',
        "alino:logit@0.0.3",
        'sanjo:jasmine@0.20.2'
    ]);
    api.addFiles([
        "lib/mongo2es.coffee",
        "lib/init.coffee",
        'tests/test.coffee'
    ], 'server');
});