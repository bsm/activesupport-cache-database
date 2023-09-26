# Changelog

## v0.5.0 (WiP)
### Added
- Adding pluggable compression for cache storage (plain and gzip supported out of the box) [#42](https://github.com/bsm/activesupport-cache-database/pull/42)
- #write_multi to insert cache in a single INSERT statement [#41](https://github.com/bsm/activesupport-cache-database/pull/41)
- Use migration generator & add a note about unlogged tables for PG [#31](https://github.com/bsm/activesupport-cache-database/pull/31)
- Use partial index for expires_at column [#28](https://github.com/bsm/activesupport-cache-database/pull/28)

### Changed
- Test with multiple DB engines; remove Rails 6.0 support [#35](https://github.com/bsm/activesupport-cache-database/pull/35)
- Retain support for Rails 6.1 [#37](https://github.com/bsm/activesupport-cache-database/pull/37)

## v0.4.0 (2023-07-18)

- Allow to clean up cache entries without `expire_at` [#24](https://github.com/bsm/activesupport-cache-database/pull/24)
