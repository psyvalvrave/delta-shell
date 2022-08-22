TARGET = sudba
WD = /tmp/$(TARGET)
INCLUDE = include
YACC = bison
LEX = flex
OBJS = susql-scanner.o susql-parser.o sudba-main.o sudba-utils.o sudba-db.o

CFLAGS = -I$(INCLUDE) -Wall -pedantic -Wextra -Wcast-align -Wcast-qual \
	-Wdisabled-optimization -Wformat=2 -Winit-self \
	-Wmissing-include-dirs -Wredundant-decls -Wshadow \
	-Wstrict-overflow=5 -Wundef -Werror -Wno-unused \
	-g -Wno-unused-result -O3 -Wno-strict-overflow -Wno-sign-compare -pthread

all: $(TARGET)

# Uncomment the end of the rule for memory debugging
sudba: $(OBJS) 
	$(CC) $(OBJS) -o $(TARGET) -pthread #-lefence 

susql-scanner.c: susql.l susql-parser.h
	$(LEX) -o susql-scanner.c susql.l

susql-parser.c susql-parser.h: susql.y
	$(YACC) -Wempty-rule -d -o susql-parser.c susql.y

sudba-main.o: sudba-main.c susql-parser.h $(INCLUDE)/sudba.h

sudba-utils.o: sudba-utils.c $(INCLUDE)/sudba.h

sudba-db.o: sudba-db.c $(INCLUDE)/sudba.h

susql-scanner.o: susql-scanner.c susql-parser.h $(INCLUDE)/sudba.h

# Remove everything that can be rebuilt
clean:
	rm -f $(OBJS) $(TARGET) susql-scanner.c susql-parser.h susql-parser.c
