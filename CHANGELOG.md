# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres roughly to [Semantic Versioning](http://semver.org/).


## [Unreleased]
### Added
### Changed
- User login checks are now case-insensitive.
- Menu items can be opened in an iFrame.
- Runnable report sql (with parameters filled-in) can be sent to a different rendererer URL to be displayed in an iFrame.
- Changed to AG-Grid 17 and the new "balham" theme.
### Fixed

## [0.1.2] - 2018-03-03
### Added
- Capistrano deploy.
### Changed
- Menu system linked to web application.
- Rake tasks respect dotenv local override for database url.

## [0.1.1] - 2018-02-21
### Changed
- Reports can be run against different databases.
- Report sets are stored per database.
- Admin of reports and grids works with several sets of reports.
- Dependency on CrossbeamsDataminerInterface has been removed.
- UI was refactored to be based on Crossbeams Framework.

## [0.1.0] - 2018-02-12
### Added
- This changelog.
### Changed
- Move to Ruby 2.5.
