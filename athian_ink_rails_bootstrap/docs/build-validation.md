# Build Validation

Validation performed in the artifact environment:

- Ruby syntax checked for all `.rb` files under `app`, `config`, `db`, `test`, and `bin`.
- JavaScript syntax checked for all Stimulus/application files with Node.
- `package.json` parsed as valid JSON.
- ERB delimiter balance scanned across all templates.
- Static dashboard preview generated at `preview/index.html`.
- Current implementation should additionally validate the local `ink_receipts` path gem, new migrations, and Rust CLI facade commands with `cargo test --workspace`.

Runtime dependency installation was not completed in this environment because Ruby 3.3.8 is not installed under rbenv and Node/npm are not on PATH. Run `bin/setup`, `bin/rails db:seed`, `bin/rails test`, `npm run build`, and `bin/dev` after installing the required toolchain.
