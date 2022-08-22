#ifndef SUDBA_H
#define SUDBA_H
#include <stdbool.h>
#include <pthread.h>

// Constants
#define DB_NAME "sudba"
#define HTTP_VER "HTTP/1.1"
#define DB_WD ("/tmp/" DB_NAME "/")
#define DB_PIDFILE (DB_NAME ".pid")
#define DB_SCHEMA_EXT ".frm"
#define DB_DATA_EXT   ".MYD"
#define DB_INDEX_EXT  ".MYI" // Not used

// Data Types
typedef struct {
  char *table;
  pthread_mutex_t lock;
} TableLock;

enum DataType {COL_INT, COL_FLOAT, COL_STR};

typedef struct {
  char *table; 
  char *column; 
} QualifiedColumn;
  
typedef struct {
  int number; 
  QualifiedColumn *values; 
} QualifiedColumns;
  
typedef struct {
  int number; 
  char **values; 
} Tables;
  
typedef struct {
  enum DataType type;
  union {
    int int_val;
    float float_val;
    char *string_val;
  } value;
} Value;

typedef struct {
  int number; 
  Value *values; 
} Values;
  
// create table student(name char(16), gpa float);
typedef struct Column {
  enum DataType type; // COL_STR // COL_FLOAT
  short width;        // 16      // n/a
  char *name;         // "name"  // "gpa"
} Column;

typedef struct Columns {
  int number; // 2
  Column *declarations; 
} Columns;
  
// General utilities
char *sudba_make_string(char *text);
void sudba_not_implemented(FILE *response);
void *my_malloc(size_t size);
void *my_realloc(void *ptr, size_t size);

// Database utilities
void sudba_lock(char *table);
void sudba_unlock(char *table);
bool sudba_exists(char *table);

// Database functions
bool sudba_drop_database(char *table, FILE *response);
bool sudba_create_database(char *table, Columns columns, FILE *response);
bool sudba_insert_into_database(char *table, Values values, FILE *response);
bool sudba_select(QualifiedColumns qc, Tables tables, void *where, FILE *response);
#endif
