<?php

// phpcs:ignoreFile

/**
 * @file
 * Drupal configuration file.
 *
 * IMPORTANT NOTE: DO NOT MODIFY THIS FILE
 *
 * There are enviornment specific files being loaded.
 *
 * 1. all.settings.php
 * 2. all.services.yml
 * 3. ${DRUPAL_ENVIRONMENT}.settings.php
 * 4. ${DRUPAL_ENVIRONMENT}.services.yml
 * 5. settings.local.php (ignored by git)
 * 6. services.local.yml (ignored by git)
 *
 */

/**
 * Database settings:
 */
if (getenv('MYSQL_DATABASE_USER')) {
    $databases['default']['default'] = [
      'database' => (getenv('MYSQL_DATABASE') ?: getenv('MYSQL_DATABASE_USER')),
      'username' => getenv('MYSQL_DATABASE_USER'),
      'password' => getenv('MYSQL_DATABASE_PW'),
      'host' => getenv('MYSQL_HOST'),
      'port' => (getenv('MYSQL_PORT') ?: '3306'),
      'driver' => (getenv('MYSQL_DATABASE_DRIVER') ?: 'mysql'),
      'prefix' => (getenv('MYSQL_DATABASE_PREFIX') ?: ''),
      'collation' => (getenv('MYSQL_DATABASE_COLLATION') ?: 'utf8mb4_general_ci'),
    ];
}

/**
 * Memcached Database settings:
 */
if (getenv('MEMCACHED_HOST')) {
    $settings['cache']['default'] = 'cache.backend.memcache_storage';
    $settings['memcache_storage']['key_prefix'] = (getenv('MEMCACHED_PREFIX') ?: '');
    $settings['memcache_storage']['memcached_servers'] = [
        (getenv('MEMCACHED_HOST') . ':' . (getenv('MEMCACHED_PORT') ?: '11211')) => 'default'
    ];
}

/**
 * Solr Database settings:
 */
if (getenv('SOLR_HOST') && getenv('SOLR_CORE')) {
    $config['search_api.server.solr']['backend_config']['connector_config']['host'] = getenv('SOLR_HOST');
    $config['search_api.server.solr']['backend_config']['connector_config']['path'] = '/';
    $config['search_api.server.solr']['backend_config']['connector_config']['core'] = getenv('SOLR_CORE');
    $config['search_api.server.solr']['backend_config']['connector_config']['port'] = (getenv('SOLR_PORT') ?: '8983');
    $config['search_api.server.solr']['backend_config']['connector_config']['http_user'] = (getenv('SOLR_USER') ?: '');
    $config['search_api.server.solr']['backend_config']['connector_config']['http']['http_user'] = (getenv('SOLR_USER') ?: '');
    $config['search_api.server.solr']['backend_config']['connector_config']['http_pass'] = (getenv('SOLR_PASSWORD') ?: '');
    $config['search_api.server.solr']['backend_config']['connector_config']['http']['http_pass'] = (getenv('SOLR_PASSWORD') ?: '');
    $config['search_api.server.solr']['name'] = 'Solr - Environment: ' . (getenv('DRUPAL_ENVIRONMENT') ?: '');
}

/**
 * Location of the site configuration files.
 */
$settings['config_sync_directory'] = '../config/sync';

/**
 * Salt for one-time login links, cancel links, form tokens, etc.
 */
$settings['hash_salt'] = (getenv('DRUPAL_HASH_SALT') ?: '');

/**
 * Access control for update.php script.
 */
$settings['update_free_access'] = FALSE;

/**
 * Public file path:
 */
$settings['file_public_path'] = 'sites/default/files';

/**
 * Private file path:
 */
if (getenv('APP_ROOT')) {
    $settings['file_private_path'] = getenv('APP_ROOT') . '/private';
} else {
$settings['file_private_path'] = '../private';#AUTO_GEN_SETT_0
}

/**
 * Temporary file path:
 */
$settings['file_temp_path'] = getenv('DRUPAL_TMP') ?: sys_get_temp_dir();

/**
 * Place Twig cache files in the temporary directory.
 * A new rolling temporary directory is provided on every code deploy,
 * guaranteeing that fresh twig cache files will be generated every time.
 * Note that the rendered output generated from the twig cache files
 * are also cached in the database, so a cache clear is still necessary
 * to see updated results after a code deploy.
 *
 * See https://github.com/pantheon-systems/drops-8/blob/default/sites/default/settings.pantheon.php
 *
 */
if (getenv('DRUPAL_DEPLOYMENT_IDENTIFIER')) {
    $settings['deployment_identifier'] = getenv('DRUPAL_DEPLOYMENT_IDENTIFIER');
    $settings['php_storage']['twig']['directory'] = $settings['file_temp_path'] . '/' . $settings['deployment_identifier'] . '/twig';
    $settings['php_storage']['twig']['secret'] = $settings['hash_salt'] . $settings['deployment_identifier'];
}

/**
 * The default list of directories that will be ignored by Drupal's file API.
 */
$settings['file_scan_ignore_directories'] = [
  'node_modules',
  'bower_components',
];

/**
 * The default number of entities to update in a batch process.
 */
$settings['entity_update_batch_size'] = 50;

/**
 * Entity update backup.
 *
 * This is used to inform the entity storage handler that the backup tables as
 * well as the original entity type and field storage definitions should be
 * retained after a successful entity update process.
 */
$settings['entity_update_backup'] = TRUE;

/**
 * Node migration type.
 *
 * This is used to force the migration system to use the classic node migrations
 * instead of the default complete node migrations. The migration system will
 * use the classic node migration only if there are existing migrate_map tables
 * for the classic node migrations and they contain data. These tables may not
 * exist if you are developing custom migrations and do not want to use the
 * complete node migrations. Set this to TRUE to force the use of the classic
 * node migrations.
 */
$settings['migrate_node_migrate_type_classic'] = FALSE;

/**
 * Load services definition file.
 */
if (file_exists($app_root . '/' . $site_path . '/services.yml')) {
    $settings['container_yamls'][] = $app_root . '/' . $site_path . '/services.yml';
}

/**
 * Load environment specific configuration and service overrides, if available.
 */

if (file_exists($app_root . '/' . $site_path . '/all.settings.php')) {
    include $app_root . '/' . $site_path . '/all.settings.php';
}

if (file_exists($app_root . '/' . $site_path . '/all.services.yml')) {
    $settings['container_yamls'][] = $app_root . '/' . $site_path . '/all.services.yml';
}

if(getenv('DRUPAL_ENVIRONMENT')){
    // Environment specific settings files.
    if (file_exists($app_root . '/' . $site_path . '/' . getenv('DRUPAL_ENVIRONMENT') . '.settings.php')) {
      include $app_root . '/' . $site_path . '/' . getenv('DRUPAL_ENVIRONMENT') . '.settings.php';
    }

    // Environment specific services files.
    if (file_exists($app_root . '/' . $site_path . '/' . getenv('DRUPAL_ENVIRONMENT') . '.services.yml')) {
      $settings['container_yamls'][] = $app_root . '/' . $site_path . '/' . getenv('DRUPAL_ENVIRONMENT') . '.services.yml';
    }
}

if(getenv('PLATFORM_ENVIRONMENT_TYPE')){
    $platform_environments = [
        "production" => "prod",
        "staging" => "stage",
        "development" => "dev"
    ];
      
    $platform_environment = "dev";
    if (array_key_exists(getenv('PLATFORM_ENVIRONMENT_TYPE'), $platform_environment)) {
    $platform_environment = $platform_environment[getenv('PLATFORM_ENVIRONMENT_TYPE')];
    }

    // Environment specific settings files.
    if (file_exists($app_root . '/' . $site_path . '/' . $platform_environment . '.settings.php')) {
      include $app_root . '/' . $site_path . '/' . $platform_environment . '.settings.php';
    }

    // Environment specific services files.
    if (file_exists($app_root . '/' . $site_path . '/' . $platform_environment . '.services.yml')) {
      $settings['container_yamls'][] = $app_root . '/' . $site_path . '/' . $platform_environment . '.services.yml';
    }
}

if (file_exists($app_root . '/' . $site_path . '/settings.platformsh.php')) {
    include $app_root . '/' . $site_path . '/settings.platformsh.php';
}

if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
    include $app_root . '/' . $site_path . '/settings.local.php';
}

if (file_exists($app_root . '/' . $site_path . '/services.local.yml')) {
    $settings['container_yamls'][] = $app_root . '/' . $site_path . '/services.local.yml';
}
