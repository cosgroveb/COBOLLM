COBC ?= cobc
PROGRAM := hello

.PHONY: all run clean

all: $(PROGRAM)

$(PROGRAM): hello.cob
	$(COBC) -x -o $@ $<

run: $(PROGRAM)
	./$(PROGRAM)

clean:
	$(RM) $(PROGRAM)
