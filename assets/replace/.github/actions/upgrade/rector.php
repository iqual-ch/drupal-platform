<?php

// @codingStandardsIgnoreFile

declare(strict_types=1);

use DrupalFinder\DrupalFinder;
use Rector\Config\RectorConfig;
use Rector\Php81\Rector\Array_\FirstClassCallableRector;
use Rector\Set\ValueObject\LevelSetList;
use DrupalRector\Set\Drupal9SetList;
use DrupalRector\Set\Drupal10SetList;

return static function (RectorConfig $rectorConfig): void {
  // Set desired version support
  $rectorConfig->sets([
    Drupal9SetList::DRUPAL_9,
    LevelSetList::UP_TO_PHP_81,
    Drupal10SetList::DRUPAL_10,
  ]);

  $drupalFinder = new DrupalFinder();
  $drupalFinder->locateRoot(__DIR__);
  $drupalRoot = $drupalFinder->getDrupalRoot();
  $rectorConfig->autoloadPaths([
    $drupalRoot . '/core',
    $drupalRoot . '/modules',
    $drupalRoot . '/profiles',
    $drupalRoot . '/themes'
  ]);

  $rectorConfig->fileExtensions(['php', 'module', 'theme', 'install', 'profile', 'inc', 'engine']);
  $rectorConfig->importNames(true, false);
  $rectorConfig->importShortClasses(false);

  $rectorConfig->skip([
    // Don't upgrade array callable to first class callable (not serializable)
    FirstClassCallableRector::class,
    // Exclude upgrade_status test modules
    '*/upgrade_status/tests/modules/*',
  ]);
};
