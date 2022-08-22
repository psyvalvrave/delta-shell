# Changelog
All notable changes to this project will be documented in this file.

## 2020-02-22

### Added
- ChangeLog.md: new file
- src/include/sudba.h: macros DB_NAME, HTTP_VER, DB_WD, DB_PIDFILE, DB_SCHEMA_EXT, DB_DATA_EXT, DB_INDEX_EXT
- src/include/sudba.h/sudba_make_string(), sudba_drop_database(), sudba_lock(), sudba_unlock(): new function prototypes
- src/makefile: support for sudba-utils.c, sudba-db.c, and some missing dependencies
- src/sudba-utils.c: new file
- src/sudba-utils.c/sudba_make_string(), sudba_drop_database(), sudba_lock(), sudba_unlock(): new function
- src/sudba-db.c: new file
- src/sudba-db.c/sudba_drop_database(): new function
- src/susql.l: int, float, id, string token values
- src/susql.y: %union for token values
- src/susql.y: %token types
- src/susql.y: call to sudba_drop_database()
