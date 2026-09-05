# Getting started

Build COBOLLM and run one task against the OpenAI Responses API.

This tutorial uses the reviewed GNU environment: Linux/aarch64, glibc 2.39 or
newer, OpenSSL 3, and `libcob.so.4`. You also need a C compiler, GNU Make,
`git`, `curl`, `tar`, and the GnuCOBOL build dependencies. Running a task also
requires a compatible Responses endpoint, an available model, and valid API
credentials.

The GNU build accepts GnuCOBOL major 3 at version 3.2 or newer. It rejects
other major versions.

1. Install the GNU build prerequisites. This package set was checked on Ubuntu
   24.04 and uses package names shared with Debian.

   ```sh
   sudo apt-get update
   sudo apt-get install --yes \
     build-essential curl xz-utils libgmp-dev libncurses-dev libxml2-dev \
     libssl-dev pkg-config binutils libc-bin coreutils tar python3 git
   ```

   This supplies the compiler build dependencies, the Python test runner, and
   `sha256sum`, `pkg-config`, `readelf`, `nm`, and `ldd` used by bootstrap or
   build checks.

2. Clone the repository and enter it.

   ```sh
   git clone https://github.com/cosgroveb/COBOLLM.git
   cd COBOLLM
   ```

3. Install the project compiler in your user data directory.

   ```sh
   make bootstrap-gnucobol
   ```

   The script downloads the official GnuCOBOL 3.2 archive, verifies its
   SHA-256 digest, builds it, and prints the environment commands for the new
   compiler. It does not install system packages.

4. Select the bootstrapped compiler.

   ```sh
   export COBC="${XDG_DATA_HOME:-$HOME/.local/share}/cobollm/gnucobol-3.2/bin/cobc"
   ```

5. Build COBOLLM.

   ```sh
   make COBC="$COBC"
   ```

   The build checks the compiler, native ABI, shared-source syntax, and native
   call inventory. It succeeds only after `./cobollm` passes the linked-binary
   checks.

6. Configure the API.

   ```sh
   export OPENAI_API_KEY='...'
   export OPENAI_MODEL='gpt-5.3-codex'
   ```

   `gpt-5.3-codex` is an example. Its availability depends on the endpoint and
   account.

7. Run one task in a disposable working tree.

   ```sh
   ./cobollm 'Inspect this repository and report what it builds.'
   ```

   COBOLLM prints shell commands and their results to standard error. The
   model's final response goes to standard output. Exit status `0` means the
   model returned a final response.

COBOLLM does not ask before executing commands. Delete the disposable working
tree if the task changed it in ways you do not want to keep.
