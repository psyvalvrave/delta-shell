%{
  /* This section is included into the output file verbatim */
  #include "sudba.h"
  #include "susql-parser.h"
#undef YY_INPUT
#define YY_INPUT(buffer, bytes_read, max_bytes) do {\
    bytes_read = read(yyget_extra(yyscanner), buffer, max_bytes);	\
  } while(0)

%}

/* May flex options that make the code thread-safe */
%option noinput nounput noyywrap 8bit nodefault                                 
%option reentrant bison-bridge bison-locations                                  
%option extra-type="int"

/* Useful macros; do you still remember regular expressions? */
intnum        [-+]?[[:digit:]]+
floatnum      [-+]?([[:digit:]]+\.[[:digit:]]*)|(\.[[:digit:]]+)
id            [[:alpha:]_][[:alnum:]_]*
string        \"([^\n\\\"]|\\.)*\"

/* Rules for recognizing tokens; (?i:...) allows case-insensitive
 * matching. Extract comments, keywords, operators, literals. We
 * ignore spaces. Everything else is reported to the parser, let it
 * handle junk */ 
%%
"-- ".*
"#".*
(?i:char)   { return YY_CHR; }
(?i:create) { return YY_CREATE; }
(?i:delete) { return YY_DELETE; }
(?i:drop)   { return YY_DROP; }
(?i:from)   { return YY_FROM; }
(?i:insert) { return YY_INSERT; }
(?i:int)    { return YY_INT; }
(?i:into)   { return YY_INTO; }
(?i:float)  { return YY_FLOAT; }
(?i:select) { return YY_SELECT; }
(?i:set)    { return YY_SET; }
(?i:table)  { return YY_TABLE; }
(?i:update) { return YY_UPDATE; }
(?i:values) { return YY_VALUES; }
(?i:where)  { return YY_WHERE; }

"!="        { return YY_NEQ; }
"<="        { return YY_LE; }
">="        { return YY_GE; }
[()*,.;<>=] { return yytext[0]; }

{intnum}    { yylval->i = atoi(yytext); return YY_INTNUM; }
{floatnum}  { yylval->f = atof(yytext); return YY_FLOATNUM; }
{id}        { yylval->s = strdup(yytext); return YY_ID; }
{string}    { yylval->s = sudba_make_string(yytext); return YY_STRING; }

[[:space:]]+

.           { return yytext[0]; }

%%

/* Parser driver */
int sudba_parse(int newsockfd)
{
  yyscan_t scanner;          
  yylex_init(&scanner);
  yylex_init_extra(newsockfd, &scanner);
  FILE* reverse_socket = fdopen(dup(newsockfd), "w");
  setlinebuf(reverse_socket);
  yyset_out(reverse_socket, scanner);
  int status = yyparse(scanner, reverse_socket);

  yylex_destroy(scanner);
  fclose(reverse_socket);
  close(newsockfd);  

  return status;
}
