<?php

// @codingStandardsIgnoreFile

declare(strict_types=1);

use DrupalFinder\DrupalFinder;
use DrupalRector\Set\Drupal9SetList;
use Rector\Config\RectorConfig;
use Rector\Core\Configuration\Option;
use Rector\Php80\Rector\FunctionLike\UnionTypesRector;
use Rector\Php81\Rector\Array_\FirstClassCallableRector;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Php80\Rector\FunctionLike\MixedTypeRector;


return static function (RectorConfig $rectorConfig): void {
  // Set desired version support
  $rectorConfig->sets([
    Drupal9SetList::DRUPAL_9,
    LevelSetList::UP_TO_PHP_81,
  ]);

  $parameters = $rectorConfig->parameters();

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
  $parameters->set('drupal_rector_notices_as_comments', true);

  $parameters->set(
    Option::SKIP,
    [
      // Don't upgrade array callable to first class callable (not serializable)
      FirstClassCallableRector::class,
      // These two rules remove @param for whatever reason
      MixedTypeRector::class,
      UnionTypesRector::class,
      // Exclude upgrade_status test modules
      '*/upgrade_status/tests/modules/*',
    ]
  );
};
