# Build Validation

Validation performed in the artifact environment:

- Ruby syntax checked for all `.rb` files under `app`, `config`, `db`, `test`, and `bin`.
- JavaScript syntax checked for all Stimulus/application files with Node.
- `package.json` parsed as valid JSON.
- ERB delimiter balance scanned across all templates.
- Static dashboard preview generated at `preview/index.html`.
- Current implementation should additionally validate the local `ink_receipts` path gem, new migrations, and Rust CLI facade commands with `cargo test --workspace`.

Runtime dependency installation was not completed in that artifact environment
because Ruby 3.3.12 and Node/npm were not available on PATH. From a clean
checkout, run `bundle install`, `npm install`, `bin/setup`, `bin/rails db:seed`,
`bin/rails test`, `npm run build`, and `bin/dev` after installing the required
toolchain. If you configure Bundler with `bundle config set --local path
vendor/bundle`, keep the generated `.bundle/` and `vendor/bundle/` directories
untracked.
