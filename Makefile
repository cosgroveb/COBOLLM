COBC ?= cobc
PROGRAM := hello

.PHONY: all run clean help

all: $(PROGRAM)

$(PROGRAM): hello.cob
	$(COBC) -x -o $@ $<

run: $(PROGRAM)
	./$(PROGRAM)

clean:
	$(RM) $(PROGRAM)

help:
	@printf '%s\n' \
		'Targets:' \
		'  all    Build hello' \
		'  run    Build and run hello' \
		'  clean  Remove hello' \
		'  help   Show this help'
