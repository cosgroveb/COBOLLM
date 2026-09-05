# How to troubleshoot a failed run

Use the first COBOLLM diagnostic and exit status to isolate the failed layer.

1. Reproduce the failure with one short task.

   ```sh
   ./cobollm 'Print the current directory.'
   printf 'exit=%s\n' "$?"
   ```

2. If the build fails before COBOL compilation, check the selected compiler.

   ```sh
   "$COBC" --version
   make COBC="$COBC" check-compiler
   make COBC="$COBC" check-gnu-abi
   ```

   COBOLLM requires GnuCOBOL major 3 at version 3.2 or newer with the matching
   `libcob.so.4`. The GNU build also rejects hosts outside its reviewed
   Linux/aarch64 ABI family.

3. Match the process status to the failing layer.

   - `2` identifies the task or `OPENAI_*` configuration.
   - `3` identifies HTTP framing, JSON, an HTTP status, or an unsupported
     Responses shape.
   - `4` identifies DNS, TCP, certificate, hostname, TLS, or AT-TLS failure.
   - `5` identifies failure to start, read, or close the shell pipe.
   - `6` identifies a fixed-capacity or text-conversion failure.

4. For status `3` with a non-2xx HTTP response, record the numeric HTTP status
   from standard error. COBOLLM discards the reason phrase and response body
   for that case. JSON, framing, and Responses-shape failures also return `3`
   but do not have a numeric HTTP diagnostic. Confirm that the endpoint
   implements the
   [required Responses subset](../reference/configuration-and-limits.md#responses-request).

5. For status `4` on GNU, verify the endpoint hostname with the public TLS
   test.

   ```sh
   make COBC="$COBC" test-net-public \
     NET_TEST_CONNECT_HOST=api.openai.com \
     NET_TEST_VERIFY_HOST=api.openai.com \
     NET_TEST_PORT=443
   ```

   Supply your endpoint's connect and verification host when they differ from
   the example. The test uses system trust paths.

6. For a z/OS network failure, verify the installed and effective AT-TLS
   policy before retrying the program. Follow
   [How to prepare the z/OS target](prepare-the-zos-target.md).

A shell command that exits nonzero does not produce process status `5`.
COBOLLM returns the exit code to the model and continues. Inspect the
`COBOLLM shell result:` block on standard error for that case.
