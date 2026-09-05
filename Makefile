DATA_HOME := $(if $(XDG_DATA_HOME),$(XDG_DATA_HOME),$(HOME)/.local/share)
BOOTSTRAP_COBC := $(DATA_HOME)/cobollm/gnucobol-3.2/bin/cobc
COBC ?= cobc
COBC_REAL := $(shell command -v $(COBC) 2>/dev/null)
COBC_LIB := $(shell $(COBC) -info 2>/dev/null | awk \
	'/^COB_LIBS/{for(i=1;i<=NF;i++)if($$i~/^-L/) \
	{print substr($$i,3);exit}}')
NATIVE_CFLAGS ?=
NATIVE_LDFLAGS ?=
NATIVE_COBFLAGS := $(foreach option,$(NATIVE_CFLAGS),-A "$(option)")
NATIVE_LINKFLAGS := $(foreach option,$(NATIVE_LDFLAGS),-Q "$(option)")
COBFLAGS := -fixed -std=ibm -Wall -Werror -I copy -I gnu/copy \
	$(NATIVE_COBFLAGS)
TESTFLAGS := $(COBFLAGS) -I test/copy
STRICTFLAGS := -fixed -std=ibm-strict -Wall -Werror -I copy -I test/copy \
	$(NATIVE_COBFLAGS)
# Contract LENGTH assertions intentionally provoke "is always FALSE";
# runtime comparisons to named fields still verify repeated literals.
CONTRACTFLAGS := $(STRICTFLAGS) -Wno-constant-numlit-expression
comma := ,
BOOTSTRAP_RPATH := $(if $(filter $(BOOTSTRAP_COBC),$(COBC_REAL)),\
	-Q "-Wl$(comma)-rpath$(comma)$(COBC_LIB)")
LINKFLAGS := -fstatic-call $(BOOTSTRAP_RPATH) $(NATIVE_LINKFLAGS)
OPENSSL_LIBS := -lssl -lcrypto
BUILD := build
PROGRAM := cobollm
GENERATED_STEMS := cobollm respapi jsonscan http11 launch netio shell \
	natutf8 output tstcontracts tstjson tsthttp tstresp tsttext tstztext \
	tstzoutput tstzbytes tstzagt tstshell tstnet tsttlsclose tstresolve tstagent \
	respcli getaddr \
	testnative tstenvch tststage popen
GENERATED_NATIVE := $(foreach stem,$(GENERATED_STEMS),\
	$(stem).c $(stem).c.h $(stem).c.l.h $(stem).c.l1.h \
	$(stem).c.l2.h $(stem).c.l3.h $(stem).c.l4.h $(stem).i)

COMMON_SOURCES := cobollm.cob respapi.cob jsonscan.cob http11.cob
GNU_SOURCES := gnu/launch.cob gnu/netio.cob gnu/shell.cob \
	gnu/natutf8.cob gnu/output.cob
SHARED_COPYBOOKS := $(wildcard copy/*.cpy)
GNU_COPYBOOKS := $(wildcard gnu/copy/*.cpy)
TEST_COPYBOOKS := $(wildcard test/copy/*.cpy)
COMMON_STRICT := cobollm.cob respapi.cob jsonscan.cob http11.cob \
	test/tstjson.cob test/tsthttp.cob \
	test/tstresp.cob test/tstshell.cob test/tstagent.cob \
	test/envchild.cob \
	test/fakes/http11.cob test/fakes/netio.cob
PRODUCTION_K := $(shell tools/native-call-flags.sh \
	$(GNU_SOURCES) $(COMMON_SOURCES))
TEXT_K := $(shell tools/native-call-flags.sh \
	test/tsttext.cob gnu/natutf8.cob)
SHELL_K := $(shell tools/native-call-flags.sh \
	test/tstshell.cob gnu/testnative.cob gnu/shell.cob gnu/output.cob)
ENV_CHILD_K := $(shell tools/native-call-flags.sh \
	test/envchild.cob gnu/testnative.cob)
STAGE_K := $(shell tools/native-call-flags.sh \
	test/tststage.cob gnu/shell.cob)
NET_K := $(shell tools/native-call-flags.sh \
	test/tstnet.cob gnu/netio.cob gnu/shell.cob)
RESOLVE_K := $(shell tools/native-call-flags.sh gnu/netio.cob)
AGENT_K := $(shell tools/native-call-flags.sh \
	test/tstagent.cob cobollm.cob http11.cob gnu/natutf8.cob \
	gnu/testnative.cob \
	test/fakes/respapi.cob test/fakes/shell.cob \
	test/fakes/output.cob test/fakes/netio.cob)
CLI_K := $(shell tools/native-call-flags.sh gnu/launch.cob \
	cobollm.cob http11.cob gnu/natutf8.cob gnu/output.cob \
	test/fakes/respcli.cob test/fakes/shell.cob \
	test/fakes/netio.cob)

.PHONY: all bootstrap-gnucobol check-compiler check-gnu-abi \
	check-common-strict check-native-calls \
	check-zos-source run test test-contracts test-json test-http \
	test-resp test-text test-shell test-net test-resolver test-net-public \
	test-agent test-make clean help

all: $(PROGRAM)

bootstrap-gnucobol:
	tools/bootstrap-gnucobol.sh

check-compiler:
	@version=`$(COBC) --version | sed -n \
	  '1s/.* \([0-9][0-9.]*\).*/\1/p'`; \
	major=$${version%%.*}; rest=$${version#*.}; minor=$${rest%%.*}; \
	if [ "$$major" != 3 ] || [ "$$minor" -lt 2 ]; then \
	  printf '%s\n' \
	    "COBOLLM needs GnuCOBOL major 3 version 3.2 or newer" \
	    "with libcob.so.4; found $${version:-unknown}" >&2; \
	  exit 1; \
	fi; \
	if [ -z "$(COBC_LIB)" ] || \
	   [ ! -f "$(COBC_LIB)/libcob.so.4" ]; then \
	  printf '%s\n' \
	    'selected cobc must report its matching libcob.so.4' >&2; \
	  exit 1; \
	fi

check-gnu-abi: check-compiler
	tools/check-gnu-abi.sh "$(COBC)"

check-common-strict: check-compiler $(COMMON_STRICT) $(SHARED_COPYBOOKS)
	@set -e; for source in $(COMMON_STRICT); do \
	  $(COBC) $(STRICTFLAGS) -fsyntax-only "$$source"; \
	done

check-native-calls:
	tools/check-native-calls.sh

check-zos-source:
	tools/check-zos-source.sh

$(BUILD):
	mkdir -p $(BUILD)

$(PROGRAM): check-gnu-abi check-common-strict check-native-calls $(BUILD) \
		$(COMMON_SOURCES) \
		$(GNU_SOURCES) $(SHARED_COPYBOOKS) $(GNU_COPYBOOKS)
	$(COBC) $(COBFLAGS) $(LINKFLAGS) $(PRODUCTION_K) -x -o $@ \
		$(GNU_SOURCES) $(COMMON_SOURCES) $(OPENSSL_LIBS)
	tools/check-gnu-link.sh $@ "$(COBC)"

$(BUILD)/test-contracts: check-compiler $(BUILD) \
		test/tstcontracts.cob $(SHARED_COPYBOOKS)
	$(COBC) $(CONTRACTFLAGS) $(LINKFLAGS) -x -o $@ \
		test/tstcontracts.cob

test-contracts: check-common-strict $(BUILD)/test-contracts
	./$(BUILD)/test-contracts

$(BUILD)/test-json: check-compiler $(BUILD) test/tstjson.cob \
		jsonscan.cob $(SHARED_COPYBOOKS)
	$(COBC) $(STRICTFLAGS) $(LINKFLAGS) -x -o $@ \
		test/tstjson.cob jsonscan.cob

test-json: check-common-strict $(BUILD)/test-json
	./$(BUILD)/test-json

$(BUILD)/test-http: check-compiler $(BUILD) test/tsthttp.cob \
		http11.cob test/fakes/netio.cob $(SHARED_COPYBOOKS)
	$(COBC) $(STRICTFLAGS) $(LINKFLAGS) -x -o $@ \
		test/tsthttp.cob http11.cob test/fakes/netio.cob

test-http: check-common-strict $(BUILD)/test-http
	./$(BUILD)/test-http

$(BUILD)/test-resp: check-compiler $(BUILD) test/tstresp.cob \
		respapi.cob jsonscan.cob test/fakes/http11.cob \
		$(SHARED_COPYBOOKS) $(TEST_COPYBOOKS)
	$(COBC) $(STRICTFLAGS) $(LINKFLAGS) -x -o $@ \
		test/tstresp.cob respapi.cob jsonscan.cob \
		test/fakes/http11.cob

test-resp: check-common-strict $(BUILD)/test-resp
	tools/check-resp-transaction.sh
	./$(BUILD)/test-resp

$(BUILD)/test-text: check-gnu-abi $(BUILD) test/tsttext.cob \
		gnu/natutf8.cob $(SHARED_COPYBOOKS) $(GNU_COPYBOOKS)
	$(COBC) $(COBFLAGS) $(LINKFLAGS) $(TEXT_K) -x -o $@ \
		test/tsttext.cob gnu/natutf8.cob
	tools/check-gnu-link.sh $@ "$(COBC)"

test-text: $(BUILD)/test-text
	./$(BUILD)/test-text

$(BUILD)/test-shell: check-gnu-abi $(BUILD) test/tstshell.cob \
		$(BUILD)/test-env-child \
		gnu/testnative.cob gnu/shell.cob gnu/output.cob \
		$(SHARED_COPYBOOKS) \
		$(GNU_COPYBOOKS)
	$(COBC) $(COBFLAGS) $(LINKFLAGS) $(SHELL_K) -x -o $@ \
		test/tstshell.cob gnu/testnative.cob gnu/shell.cob \
		gnu/output.cob
	tools/check-gnu-link.sh $@ "$(COBC)"

$(BUILD)/test-env-child: check-gnu-abi $(BUILD) test/envchild.cob \
		gnu/testnative.cob
	$(COBC) $(COBFLAGS) $(LINKFLAGS) $(ENV_CHILD_K) -x -o $@ \
		test/envchild.cob gnu/testnative.cob
	tools/check-gnu-link.sh $@ "$(COBC)"

$(BUILD)/stage-shell.o: check-gnu-abi $(BUILD) gnu/shell.cob \
		$(SHARED_COPYBOOKS) $(GNU_COPYBOOKS)
	$(COBC) $(TESTFLAGS) $(STAGE_K) -c -o $@ gnu/shell.cob

$(BUILD)/stage-popen.o: check-gnu-abi $(BUILD) \
		test/fakes/popen.cob test/copy/POPFCTRL.cpy \
		$(SHARED_COPYBOOKS)
	$(COBC) $(TESTFLAGS) -Wno-unfinished -c -o $@ \
		test/fakes/popen.cob

$(BUILD)/stage-native.o: $(BUILD)/stage-shell.o \
		$(BUILD)/stage-popen.o
	ld -r -o $@ $^
	objcopy --localize-symbol=popen $@

$(BUILD)/test-shell-stage: check-gnu-abi $(BUILD) test/tststage.cob \
		$(BUILD)/stage-native.o test/copy/POPFCTRL.cpy \
		$(SHARED_COPYBOOKS)
	$(COBC) $(TESTFLAGS) $(LINKFLAGS) $(STAGE_K) -x -o $@ \
		test/tststage.cob $(BUILD)/stage-native.o
	tools/check-gnu-link.sh $@ "$(COBC)"

test-shell: $(BUILD)/test-shell $(BUILD)/test-shell-stage
	./$(BUILD)/test-shell
	./$(BUILD)/test-shell-stage

$(BUILD)/tlsclose-netio.o: check-gnu-abi $(BUILD) gnu/netio.cob \
		$(SHARED_COPYBOOKS) $(GNU_COPYBOOKS)
	$(COBC) $(COBFLAGS) $(RESOLVE_K) -c -o $@ gnu/netio.cob

$(BUILD)/tlsclose-fake.o: check-gnu-abi $(BUILD) \
		test/fakes/tlsclose.cob $(SHARED_COPYBOOKS) $(GNU_COPYBOOKS) \
		$(TEST_COPYBOOKS)
	$(COBC) $(TESTFLAGS) -Wno-unfinished -c -o $@ \
		test/fakes/tlsclose.cob

$(BUILD)/tlsclose-native.o: $(BUILD)/tlsclose-netio.o \
		$(BUILD)/tlsclose-fake.o
	ld -r -o $@ $^
	objcopy --localize-symbol=SSL_shutdown \
		--localize-symbol=SSL_get_error $@

$(BUILD)/test-tls-close: check-gnu-abi $(BUILD) test/tsttlsclose.cob \
		$(BUILD)/tlsclose-native.o $(SHARED_COPYBOOKS) \
		$(GNU_COPYBOOKS) $(TEST_COPYBOOKS)
	$(COBC) $(TESTFLAGS) $(LINKFLAGS) $(RESOLVE_K) -x -o $@ \
		test/tsttlsclose.cob $(BUILD)/tlsclose-native.o \
		$(OPENSSL_LIBS)
	tools/check-gnu-link.sh $@ "$(COBC)"

$(BUILD)/test-net: check-gnu-abi $(BUILD) test/tstnet.cob \
		gnu/netio.cob gnu/shell.cob $(SHARED_COPYBOOKS) $(GNU_COPYBOOKS)
	$(COBC) $(COBFLAGS) $(LINKFLAGS) $(NET_K) -x -o $@ \
		test/tstnet.cob gnu/netio.cob gnu/shell.cob $(OPENSSL_LIBS)
	tools/check-gnu-link.sh $@ "$(COBC)"

$(BUILD)/resolve-netio.o: check-gnu-abi $(BUILD) gnu/netio.cob \
		$(SHARED_COPYBOOKS) $(GNU_COPYBOOKS)
	$(COBC) $(COBFLAGS) $(RESOLVE_K) -c -o $@ gnu/netio.cob

$(BUILD)/resolve-getaddr.o: check-gnu-abi $(BUILD) \
		test/fakes/getaddr.cob $(SHARED_COPYBOOKS) $(TEST_COPYBOOKS)
	$(COBC) $(TESTFLAGS) -Wno-unfinished -c -o $@ \
		test/fakes/getaddr.cob

$(BUILD)/resolve-native.o: $(BUILD)/resolve-netio.o \
		$(BUILD)/resolve-getaddr.o
	ld -r -o $@ $^
	objcopy --localize-symbol=getaddrinfo \
		--localize-symbol=freeaddrinfo $@

$(BUILD)/test-resolver: check-gnu-abi $(BUILD) test/tstresolve.cob \
		$(BUILD)/resolve-native.o $(SHARED_COPYBOOKS) $(TEST_COPYBOOKS)
	$(COBC) $(TESTFLAGS) $(LINKFLAGS) -x -o $@ \
		test/tstresolve.cob $(BUILD)/resolve-native.o $(OPENSSL_LIBS)
	tools/check-gnu-link.sh $@ "$(COBC)"

test-resolver: $(BUILD)/test-net $(BUILD)/test-resolver \
		$(BUILD)/test-tls-close
	test/netserver.py ./$(BUILD)/test-net ./$(BUILD)/test-resolver \
		./$(BUILD)/test-tls-close

test-net: test-resolver

test-net-public: $(BUILD)/test-net
	./$(BUILD)/test-net public "$(NET_TEST_CONNECT_HOST)" \
		"$(NET_TEST_VERIFY_HOST)" "$(NET_TEST_PORT)"

$(BUILD)/test-agent: check-gnu-abi check-common-strict $(BUILD) \
		test/tstagent.cob cobollm.cob http11.cob gnu/natutf8.cob \
		gnu/testnative.cob \
		test/fakes/respapi.cob test/fakes/shell.cob \
		test/fakes/output.cob test/fakes/netio.cob $(TEST_COPYBOOKS)
	$(COBC) $(TESTFLAGS) $(LINKFLAGS) $(AGENT_K) -x -o $@ \
		test/tstagent.cob cobollm.cob http11.cob gnu/natutf8.cob \
		gnu/testnative.cob \
		test/fakes/respapi.cob test/fakes/shell.cob \
		test/fakes/output.cob test/fakes/netio.cob
	tools/check-gnu-link.sh $@ "$(COBC)"

$(BUILD)/test-cli: check-gnu-abi check-common-strict $(BUILD) \
		gnu/launch.cob cobollm.cob http11.cob gnu/natutf8.cob \
		gnu/output.cob test/fakes/respcli.cob \
		test/fakes/shell.cob test/fakes/netio.cob \
		$(SHARED_COPYBOOKS) $(GNU_COPYBOOKS) $(TEST_COPYBOOKS)
	$(COBC) $(TESTFLAGS) $(LINKFLAGS) $(CLI_K) -x -o $@ \
		gnu/launch.cob cobollm.cob http11.cob gnu/natutf8.cob \
		gnu/output.cob test/fakes/respcli.cob \
		test/fakes/shell.cob test/fakes/netio.cob
	tools/check-gnu-link.sh $@ "$(COBC)"

test-agent: $(BUILD)/test-agent $(BUILD)/test-cli
	./$(BUILD)/test-agent
	test/testcli.py ./$(BUILD)/test-cli

test-make:
	test/testmake.py

test: check-common-strict test-contracts test-json test-http test-resp \
	test-text test-shell test-net test-agent test-make check-zos-source \
	check-native-calls

run: export COBOLLM_RUN_TASK := $(value TASK)
run: $(PROGRAM)
	@test -n "$$COBOLLM_RUN_TASK" || { \
	  printf '%s\n' 'usage: make run TASK="your task"' >&2; exit 2; \
	}
	./$(PROGRAM) "$$COBOLLM_RUN_TASK"

clean:
	$(RM) $(PROGRAM)
	$(RM) -r $(BUILD)
	$(RM) -r test/__pycache__
	$(RM) $(GENERATED_NATIVE)

help:
	@printf '%s\n' \
	  'GNU/Linux prerequisites:' \
	  '  Linux/aarch64, glibc 2.39+, OpenSSL 3' \
	  '  GnuCOBOL 3.2+ with libcob.so.4' \
	  'Targets:' \
	  '  all                Build cobollm after ABI and link gates' \
	  '  run TASK="..."     Opt in to a credentialed Responses API call' \
	  '                     Uses supplied OPENAI_* configuration' \
	  '  test               Run controlled GNU tests and source gates' \
	  '  test-{contracts,json,http,resp,text,shell}' \
	  '  test-{net,resolver,agent}' \
	  '                     Run one deterministic component test' \
	  '  test-net-public    Opt in to caller-supplied public TLS endpoint' \
	  '    NET_TEST_CONNECT_HOST=host NET_TEST_VERIFY_HOST=host' \
	  '    NET_TEST_PORT=443' \
	  '  check-compiler     Require GnuCOBOL 3.2+ and libcob.so.4' \
	  '  check-gnu-abi      Require reviewed Linux/aarch64 ABI family' \
	  '  check-common-strict Check shared source with IBM strict dialect' \
	  '  check-zos-source   Validate z/OS transfer source bytes' \
	  '  bootstrap-gnucobol Install pinned GnuCOBOL 3.2 locally' \
	  '  check-native-calls Audit native call/link inventory' \
	  '  clean              Remove generated GNU artifacts' \
	  '  help               Show this help'
