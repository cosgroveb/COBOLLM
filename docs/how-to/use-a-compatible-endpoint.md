# How to use a compatible endpoint

Point COBOLLM at an endpoint that implements the required OpenAI Responses
request and response shapes.

1. Confirm that the endpoint implements the
   [required Responses subset](../reference/configuration-and-limits.md#responses-request).

2. Set a base URL without the `/responses` suffix.

   ```sh
   export OPENAI_BASE_URL='https://gateway.example.com/v1'
   ```

   COBOLLM removes trailing slashes and appends `/responses`.

3. Set the model identifier accepted by that endpoint.

   ```sh
   export OPENAI_MODEL='gpt-5.3-codex'
   ```

   `gpt-5.3-codex` is an example. Its availability depends on the endpoint and
   account.

4. Set the bearer token.

   ```sh
   export OPENAI_API_KEY='...'
   ```

5. Run a task.

   ```sh
   ./cobollm 'List the files in the current directory.'
   ```

GNU builds permit `http://` for local testing. COBOLLM prints a warning before
it sends the bearer token or conversation without encryption. z/OS rejects
plain HTTP.
