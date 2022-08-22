%define api.pure full
%locations
%param { yyscan_t scanner } { FILE* yyoutfile }

%code top {
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sudba.h"
 }

%code requires {
  int sudba_parse(int socket /* unused */);
  typedef void* yyscan_t;
  FILE *get_yyout(yyscan_t scanner);
 }

%code {
  int yylex(YYSTYPE* yylvalp, YYLTYPE* yyllocp, yyscan_t scanner, FILE* yyoutfile);
  void yyerror(YYLTYPE* yyllocp, yyscan_t unused, FILE* yyoutfile, const char* msg);
 }

%union{
  int i;
  float f;
  char *s;
  Tables tables;
  Column column;
  Columns columns;
  QualifiedColumn qcolumn;
  QualifiedColumns qcolumns;
  Value value;
  Values values;
  }

/* Data types */
%token<f> YY_FLOATNUM
%token<s> YY_ID
%token<i> YY_INTNUM
%token<s> YY_STRING

 /* Keywords */
%token YY_CHR
%token YY_CREATE
%token YY_DELETE
%token YY_DROP
%token YY_FLOAT
%token YY_FROM
%token YY_GE
%token YY_INSERT
%token YY_INT
%token YY_INTO
%token YY_LE
%token YY_NEQ
%token YY_SELECT
%token YY_SET
%token YY_TABLE
%token YY_UPDATE
%token YY_VALUES
%token YY_WHERE

%type <column> type spec
%type <columns> spec-list
%type <value> value
%type <values> valist
%type <tables> tables
%type <qcolumn> column
%type <qcolumns> column-list

%start script

%%

script:
  query ';' { YYACCEPT; }

query:
  create-query 
| drop-query   
| insert-query
| select-query 
| update-query { sudba_not_implemented(yyoutfile); }
| delete-query { sudba_not_implemented(yyoutfile); }
;

create-query:
  YY_CREATE YY_TABLE YY_ID '(' spec-list ')' {
    sudba_create_database($3, $5, yyoutfile);
  };

spec-list: /* a comma-separated list of column declarations */
  spec {
    /* The first column declaration */
    $$.declarations = my_malloc(sizeof(Column));
    $$.declarations[0] = $1;
    $$.number = 1;
  }
| spec-list ',' spec {
  /* More column declarations */
  $$.declarations = my_realloc($1.declarations, sizeof(Column) * ($1.number + 1));
  $$.declarations[$$.number] = $3;
  $$.number++;
  }
;

spec: /* column name and datatype, as in "id int, name char(16)" */
  YY_ID type { $2.name = $1; $$ = $2; } ;

type: /* on of the three supported datatypes */
  YY_INT                   { Column c = { COL_INT,   0, NULL }; $$ = c; } 
| YY_FLOAT                 { Column c = { COL_FLOAT, 0, NULL }; $$ = c; } 
| YY_CHR '(' YY_INTNUM ')' { Column c = { COL_STR,  $3, NULL }; $$ = c; } 
;

drop-query:
YY_DROP YY_TABLE YY_ID { sudba_drop_database($3, yyoutfile); }
;

insert-query:
  YY_INSERT YY_INTO YY_ID YY_VALUES '(' valist ')' {
    sudba_insert_into_database($3, $6, yyoutfile);
  }
;

valist:
  value {
  /* The first value */
    $$.values = my_malloc(sizeof(Value));
    $$.values[0] = $1;
    $$.number = 1;
  }
| valist ',' value {
  /* More values */
  $$.values = my_realloc($1.values, sizeof(Value) * ($1.number + 1));
  $$.values[$$.number] = $3;
  $$.number++;
  }
;

value:
  YY_INTNUM   { $$.type = COL_INT;   $$.value.int_val    = $1; }
| YY_FLOATNUM { $$.type = COL_FLOAT; $$.value.float_val  = $1; }
| YY_STRING   { $$.type = COL_STR;   $$.value.string_val = $1; }
;

select-query: 
  YY_SELECT column-list YY_FROM tables where-clause {
    sudba_select($2, $4, NULL, yyoutfile);
}
;

column-list:
  column {
    $$.number = 1;
    $$.values = my_malloc(sizeof(QualifiedColumn)); $$.values[0] = $1; }
| column-list ',' column {
    $$.number++;
    $$.values = my_realloc($$.values, sizeof(QualifiedColumn) * $$.number);
    $$.values[$$.number - 1] = $3; 
  }
;

column:
YY_ID { $$.table = NULL; $$.column = $1; }
| YY_ID '.' YY_ID { $$.table = $1; $$.column = $3; }
| '*' { $$.table = NULL; $$.column = NULL; }
;

tables :
YY_ID {
  $$.number = 1;
  $$.values = my_malloc(sizeof(char*));
  $$.values[0] = $1; }
| tables ',' YY_ID {
  $$.number++;
  $$.values = my_realloc($$.values, sizeof(char*) * $$.number);
  $$.values[$$.number - 1] = $3; }
;

where-clause:
  %empty /* empty clause */
| YY_WHERE condition
;

column-ref:
  YY_ID { free($1); /* temp measure */ }
| YY_ID '.' YY_ID { free($1); free($3); /* temp measure */ }
;

column-or-val:
  column-ref
| value
;

condition:
  column-ref '='    column-or-val
| column-ref '>'    column-or-val
| column-ref '<'    column-or-val
| column-ref YY_NEQ column-or-val
| column-ref YY_GE  column-or-val
| column-ref YY_LE  column-or-val
;

delete-query: /* TODO */
  YY_DELETE YY_FROM YY_ID where-clause { free($3); /* temp measure */ }
;

update-query: /* TODO */
YY_UPDATE YY_ID YY_SET YY_ID '=' column-or-val where-clause { free($2); free($4); /* temp measure */ }
; 

%%
