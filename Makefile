COBC ?= cobc
COBFLAGS ?= -fixed -std=ibm-strict -I copy
PROGRAM := hello
TEST_PROGRAM := test-hello
PROGRAM_SOURCES := hello.cob greeter.cob
TEST_SOURCES := test/tsthello.cob greeter.cob
COPYBOOKS := copy/HELLOMSG.cpy

.PHONY: all run test clean help

all: $(PROGRAM)

$(PROGRAM): $(PROGRAM_SOURCES) $(COPYBOOKS)
	$(COBC) $(COBFLAGS) -x -o $@ $(PROGRAM_SOURCES)

$(TEST_PROGRAM): $(TEST_SOURCES) $(COPYBOOKS)
	$(COBC) $(COBFLAGS) -x -o $@ $(TEST_SOURCES)

run: $(PROGRAM)
	./$(PROGRAM)

test: $(TEST_PROGRAM)
	./$(TEST_PROGRAM)

clean:
	$(RM) $(PROGRAM) $(TEST_PROGRAM)

help:
	@printf '%s\n' \
		'Targets:' \
		'  all    Build hello' \
		'  run    Build and run hello' \
		'  test   Build and run unit tests' \
		'  clean  Remove built programs' \
		'  help   Show this help'
