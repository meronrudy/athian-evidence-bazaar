"""Command line interface for the AgEvidence Python SDK."""

from __future__ import annotations

import json
from pathlib import Path

import typer

from .campaign_cli import register_campaign_cli
from .adapters import test_source_adapter
from .cli_support import client_factory as _client
from .cli_support import console, emit as _emit, handle_error as _handle_error
from .config import SDKConfig
from .country_cli import register_country_cli
from .demo import run_demo
from .doctor import doctor as _doctor
from .events import load_event, project_4030_event_files, sign_hmac_event
from .explain import explain as _explain
from .exports import export_evidence as _export_evidence
from .fixtures import fixture_names, load_fixture, write_fixture
from .ingest import ingest as _ingest
from .profiles import get_domain_profile, list_domain_profiles
from .proofkits import list_proofkits, run_proofkit, write_proofkit
from .verification import Verifier

app = typer.Typer(help="AgEvidence Developer OS CLI")
source_adapter_app = typer.Typer(help="Source adapter commands")
fixture_app = typer.Typer(help="Local synthetic fixture commands")
proof_app = typer.Typer(help="Wave proof-kit commands")
profile_app = typer.Typer(help="Domain profile commands")
project_app = typer.Typer(help="Project commands")
source_app = typer.Typer(help="Source-record commands")
model_app = typer.Typer(help="Model-run commands")
pricing_app = typer.Typer(help="Pricing commands")
quote_app = typer.Typer(help="Quote commands")
order_app = typer.Typer(help="Artifact order commands")
artifact_app = typer.Typer(help="Artifact commands")
operation_app = typer.Typer(help="Operation commands")
event_app = typer.Typer(help="Evidence Event Inbox commands")
replay_app = typer.Typer(help="Replay fixture scenarios")

app.add_typer(source_adapter_app, name="adapter")
app.add_typer(fixture_app, name="fixture")
app.add_typer(proof_app, name="proof")
app.add_typer(profile_app, name="profile")
app.add_typer(project_app, name="project")
app.add_typer(source_app, name="source")
app.add_typer(model_app, name="model")
app.add_typer(pricing_app, name="pricing")
app.add_typer(quote_app, name="quote")
app.add_typer(order_app, name="order")
app.add_typer(artifact_app, name="artifact")
app.add_typer(operation_app, name="operation")
app.add_typer(event_app, name="event")
app.add_typer(replay_app, name="replay")
register_country_cli(app)
register_campaign_cli(app)


@app.command("demo")
def demo(name: str = typer.Option("livestock-weight", "--fixture"), output: str = typer.Option("table", "--format")) -> None:
    """Run a local no-account deterministic evidence demo."""

    try:
        result = run_demo(name)
        if output == "table":
            console.print("Agevidence Developer Demo")
            console.print(f"Loaded: {result.fixture}")
            console.print(f"Mapped: {result.primitive_type}")
            console.print(f"Structural validity: {result.structural_validity.upper()}")
            console.print(f"Provenance completeness: {result.provenance_completeness.upper()} ({result.provenance_score}%)")
            console.print(f"Rust validation: {result.rust_validation.upper()}")
            console.print("No account used. No API key used. No network request used.")
            return
        _emit(result, output)
    except Exception as exc:
        _handle_error(exc)


@app.command("doctor")
def doctor_command(output: str = typer.Option("table", "--format")) -> None:
    """Check local SDK readiness without requiring hosted services."""

    try:
        report = _doctor()
        if output == "json":
            _emit(report, "json")
        else:
            console.print("Agevidence SDK")
            for check in report.checks:
                status = check.status.upper()
                console.print(f"{check.name:<28} {status}")
                if check.detail:
                    console.print(f"{'':<28} {check.detail}")
            console.print("READY FOR LOCAL DEVELOPMENT" if report.ready else "LOCAL DEVELOPMENT BLOCKED")
        if not report.ready:
            raise typer.Exit(code=1)
    except typer.Exit:
        raise
    except Exception as exc:
        _handle_error(exc)


@app.command("ingest")
def ingest_command(
    record: Path = typer.Argument(..., exists=True),
    primitive: str = typer.Option("auto", "--primitive"),
    profile: str | None = typer.Option(None, "--profile", help="Optional reusable domain profile id or alias."),
    output: str = typer.Option("json", "--format"),
) -> None:
    """Infer a local evidence primitive from native JSON."""

    try:
        result = _ingest(record, primitive=primitive, profile=profile)
        if output == "table":
            _print_ingest_table(result)
            return
        _emit(result, output)
    except Exception as exc:
        _handle_error(exc)


@app.command("explain")
def explain_command(record: Path = typer.Argument(..., exists=True), output: str = typer.Option("json", "--format")) -> None:
    """Explain local evidence readiness and missing provenance."""

    try:
        report = _explain(record)
        if output == "table":
            _print_explain_table(report)
            return
        _emit(report, output)
    except Exception as exc:
        _handle_error(exc)


@app.command("export")
def export_command(
    record: Path = typer.Argument(..., exists=True),
    primitive: str = typer.Option("auto", "--primitive"),
    output: str = typer.Option("json", "--format"),
) -> None:
    """Export a portable local evidence envelope."""

    try:
        _emit(_export_evidence(record, primitive=primitive), output)
    except Exception as exc:
        _handle_error(exc)


@source_adapter_app.command("test")
def source_adapter_test(
    adapter: str = typer.Argument(..., help="Adapter spec: path.py, path.py:ObjectName, or module:ObjectName."),
    fixtures: Path = typer.Argument(..., exists=False, help="JSON fixture file or directory."),
    output: str = typer.Option("table", "--format"),
) -> None:
    """Test a source-system adapter against native JSON fixtures."""

    try:
        report = test_source_adapter(adapter, fixtures)
        if output == "table":
            _print_source_adapter_report(report)
        else:
            _emit(report, output)
        if not report.passed:
            raise typer.Exit(code=1)
    except typer.Exit:
        raise
    except Exception as exc:
        _handle_error(exc)


@fixture_app.command("list")
def fixture_list(output: str = typer.Option("json", "--format")) -> None:
    """List local synthetic fixtures."""

    try:
        _emit({"fixtures": fixture_names()}, output)
    except Exception as exc:
        _handle_error(exc)


@fixture_app.command("show")
def fixture_show(name: str = typer.Argument(...), output: str = typer.Option("json", "--format")) -> None:
    """Show a local synthetic fixture payload."""

    try:
        _emit(load_fixture(name), output)
    except Exception as exc:
        _handle_error(exc)


@fixture_app.command("write")
def fixture_write(name: str = typer.Argument(...), out: Path = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    """Write a local synthetic fixture payload to a JSON file."""

    try:
        _emit({"path": str(write_fixture(name, out))}, output)
    except Exception as exc:
        _handle_error(exc)


@proof_app.command("list")
def proof_list(output: str = typer.Option("table", "--format")) -> None:
    """List packaged Wave 1/2 local proof kits."""

    try:
        proofkits = list_proofkits()
        if output == "table":
            _print_proofkit_list(proofkits)
            return
        _emit({"proofkits": [proofkit.model_dump(mode="json") for proofkit in proofkits]}, output)
    except Exception as exc:
        _handle_error(exc)


@proof_app.command("run")
def proof_run(
    proof_id: str = typer.Argument(...),
    output: str = typer.Option("table", "--format"),
    rust_validate: bool = typer.Option(False, "--rust-validate"),
    issue_receipt_projection: bool = typer.Option(False, "--issue-receipt-projection"),
    verifier_command: str | None = typer.Option(None, "--verifier-command", help="Rust verifier command, for example target/debug/baink-cli."),
) -> None:
    """Run a 60-second local proof kit for a partner-shaped native record."""

    try:
        result = run_proofkit(
            proof_id,
            rust_validate=rust_validate,
            issue_receipt_projection=issue_receipt_projection,
            verifier_command=verifier_command,
        )
        if output == "table":
            _print_proofkit_run(result)
        else:
            _emit(result, output)
        if any(item.status == "fail" for item in [*result.rust_validation, *result.receipt_projections]):
            raise typer.Exit(code=1)
    except typer.Exit:
        raise
    except Exception as exc:
        _handle_error(exc)


@proof_app.command("write")
def proof_write(proof_id: str = typer.Argument(...), out: Path = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    """Write a proof-kit fixture, expected output, README, and adapter shim."""

    try:
        _emit({"paths": write_proofkit(proof_id, out)}, output)
    except Exception as exc:
        _handle_error(exc)


@profile_app.command("list")
def profile_list(output: str = typer.Option("table", "--format")) -> None:
    """List reusable domain profiles."""

    try:
        profiles = list_domain_profiles()
        if output == "table":
            _print_profile_list(profiles)
            return
        _emit({"profiles": [profile.metadata.model_dump(mode="json") for profile in profiles]}, output)
    except Exception as exc:
        _handle_error(exc)


@profile_app.command("inspect")
def profile_inspect(profile_id: str = typer.Argument(...), output: str = typer.Option("json", "--format")) -> None:
    """Inspect one reusable domain profile by id or alias."""

    try:
        profile = get_domain_profile(profile_id)
        if output == "table":
            _print_profile(profile)
            return
        _emit(profile.metadata, output)
    except Exception as exc:
        _handle_error(exc)


@app.command()
def login(
    base_url: str = typer.Option("http://localhost:3000", help="Rails Developer OS base URL."),
    api_token: str | None = typer.Option(None, help="Reserved for future authenticated deployments."),
    integration_source: str | None = typer.Option(None, help="Default integration source for event commands."),
    verifier_command: str | None = typer.Option(None, help="External verifier command, for example target/debug/baink-cli."),
) -> None:
    """Write local CLI configuration."""

    path = SDKConfig(
        base_url=base_url,
        api_token=api_token,
        integration_source=integration_source,
        verifier_command=verifier_command,
    ).save()
    console.print(f"Saved AgEvidence config to {path}")


@project_app.command("create")
def project_create(
    account_name: str = typer.Option(...),
    name: str = typer.Option(...),
    target_claim: str = typer.Option(...),
    funding_stage: str = typer.Option("sandbox"),
    project_type: str = typer.Option("intervention"),
    external_project_id: str | None = typer.Option(None),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(
            _client().create_project(
                account_name=account_name,
                project_name=name,
                target_claim=target_claim,
                funding_stage=funding_stage,
                project_type=project_type,
                external_project_id=external_project_id,
            ),
            output,
        )
    except Exception as exc:
        _handle_error(exc)


@source_app.command("add")
def source_add(
    project_id: str = typer.Option(...),
    document_id: str = typer.Option(...),
    evidence_type: str = typer.Option(...),
    controlled_uri: str = typer.Option(...),
    commitment: str = typer.Option(...),
    source_system: str = typer.Option("agevidence_cli"),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(
            _client().submit_source_record(
                project_id=project_id,
                document_id=document_id,
                evidence_type=evidence_type,
                controlled_uri=controlled_uri,
                commitment=commitment,
                source_system=source_system,
            ),
            output,
        )
    except Exception as exc:
        _handle_error(exc)


@model_app.command("run")
def model_run(project_id: str = typer.Option(...), adapter_id: str = typer.Option("qwen3.5-4b-reference"), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().run_model(project_id=project_id, adapter_id=adapter_id), output)
    except Exception as exc:
        _handle_error(exc)


@app.command()
def review(
    candidate_id: str = typer.Option(...),
    decision: str = typer.Option(...),
    reason: str = typer.Option(...),
    reviewer_role: str = typer.Option("scientific_reviewer_sandbox"),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(_client().review_candidate(candidate_id=candidate_id, decision=decision, reason=reason, reviewer_role=reviewer_role), output)
    except Exception as exc:
        _handle_error(exc)


@pricing_app.command("products")
def pricing_products(output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().list_products(), output)
    except Exception as exc:
        _handle_error(exc)


@quote_app.command("create")
def quote_create(
    project_id: str = typer.Option(...),
    product_code: str = typer.Option(...),
    scope_json: str = typer.Option("{}", help="JSON object of pricing scope factors."),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(_client().create_quote(project_id=project_id, product_code=product_code, scope=json.loads(scope_json)), output)
    except Exception as exc:
        _handle_error(exc)


@order_app.command("create")
def order_create(quote_id: str = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().create_order(quote_id=quote_id), output)
    except Exception as exc:
        _handle_error(exc)


@order_app.command("checkout")
def order_checkout(order_id: str = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().checkout_order(order_id=order_id), output)
    except Exception as exc:
        _handle_error(exc)


@artifact_app.command("build")
def artifact_build(
    project_id: str = typer.Option(...),
    order_id: str | None = typer.Option(None),
    quote_id: str | None = typer.Option(None),
    product_code: str | None = typer.Option(None),
    sandbox_checkout: bool = typer.Option(False),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(
            _client().build_artifact(
                project_id=project_id,
                order_id=order_id,
                quote_id=quote_id,
                product_code=product_code,
                sandbox_checkout=sandbox_checkout,
            ),
            output,
        )
    except Exception as exc:
        _handle_error(exc)


@artifact_app.command("show")
def artifact_show(project_id: str = typer.Option(...), artifact_id: str = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().get_artifact(project_id=project_id, artifact_id=artifact_id), output)
    except Exception as exc:
        _handle_error(exc)


@operation_app.command("wait")
def operation_wait(operation_id: str = typer.Option(...), timeout: float = typer.Option(60.0), interval: float = typer.Option(2.0), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().wait_for_operation(operation_id, timeout=timeout, interval=interval), output)
    except Exception as exc:
        _handle_error(exc)


@event_app.command("submit")
def event_submit(
    file: Path = typer.Option(..., exists=True),
    source: str = typer.Option(...),
    timestamp: str = typer.Option(...),
    signature: str = typer.Option(...),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(_client().submit_event(load_event(file), source=source, timestamp=timestamp, signature=signature), output)
    except Exception as exc:
        _handle_error(exc)


@event_app.command("replay")
def event_replay(event_id: str = typer.Option(...), source: str | None = typer.Option(None), reason: str = typer.Option("agevidence_cli_replay"), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().replay_event(event_id, source=source, reason=reason), output)
    except Exception as exc:
        _handle_error(exc)


@replay_app.command("project-4030")
def replay_project_4030(
    fixture_root: Path | None = typer.Option(None, help="Override Project 4030 fixture directory."),
    source: str | None = typer.Option(None),
    secret: str | None = typer.Option(None),
    campaign_account_id: str | None = typer.Option(None),
    activation_id: str | None = typer.Option(None),
    repository_sha: str | None = typer.Option("f4ec679c2dd6a2c40e3dced61c81e8f59f90a397"),
    output: str = typer.Option("json", "--format"),
) -> None:
    """Sign and replay the eight-event Project 4030 scenario."""

    config = SDKConfig.load()
    source_key = source or config.integration_source or "athian_salesforce_production"
    signing_secret = secret or config.integration_secret or "demo-integration-secret"
    client = _client(campaign_account_id=campaign_account_id, activation_id=activation_id, repository_sha=repository_sha)
    results = []
    try:
        for path in project_4030_event_files(fixture_root):
            event = sign_hmac_event(load_event(path), source=source_key, secret=signing_secret)
            submitted = client.submit_event(
                event,
                source=source_key,
                timestamp=event["occurred_at"],
                signature=event["integrity"]["signature"],
            )
            results.append({"file": path.name, **submitted.model_dump(mode="json", exclude_none=True)})
        campaign_result = None
        if campaign_account_id and activation_id:
            campaign_result = client.campaign.complete_activation(campaign_account_id, activation_id).model_dump(mode="json", exclude_none=True)
        _emit({"events": results, "campaign_activation": campaign_result}, output)
    except Exception as exc:
        _handle_error(exc)


@app.command()
def verify(
    bundle: Path | None = typer.Argument(None, exists=False),
    bundle_option: Path | None = typer.Option(None, "--bundle", exists=False, help="Bundle JSON path. Kept for v0.1 CLI compatibility."),
    output: str = typer.Option("text", "--format"),
) -> None:
    """Delegate bundle verification to the configured Rust verifier."""

    try:
        selected = bundle or bundle_option
        if selected is None:
            raise typer.BadParameter("Provide a bundle path.")
        result = Verifier().verify_bundle(selected)
        if output == "json":
            _emit(result, "json")
            return
        status = _verification_status(result.stdout)
        console.print(f"Verification {status}")
    except Exception as exc:
        _handle_error(exc)


def _verification_status(stdout: str) -> str:
    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError:
        return "DELEGATED"
    return str(payload.get("status") or "DELEGATED")


def _status(value: str) -> str:
    return value.upper()


def _print_ingest_table(result) -> None:
    console.print("Agevidence Ingest")
    console.print(f"Candidate primitive: {result.primitive_type}")
    console.print(f"Confidence: {result.confidence}")
    if result.candidates:
        console.print(f"Mapped fields: {', '.join(result.candidates[0].matched_fields)}")
    console.print(f"Structural validity: {_status(result.provenance.structural_validity)}")
    console.print(f"Provenance completeness: {_status(result.provenance.provenance_completeness)} ({result.provenance.score}%)")
    console.print(f"Local digest: {result.local_digest}")
    if result.profile_application:
        console.print(f"Profile: {result.profile_application['profile_id']}")
        console.print(f"Profile status: {_status(result.profile_application['status'])}")
    console.print(result.provenance.authority_boundary)


def _print_explain_table(report) -> None:
    console.print("Agevidence Explain")
    console.print(f"Primitive: {report.primitive_type}")
    console.print(f"Summary: {report.summary}")
    console.print(f"Structural validity: {_status(report.provenance.structural_validity)}")
    console.print(f"Provenance completeness: {_status(report.provenance.provenance_completeness)} ({report.provenance.score}%)")
    if report.missing:
        console.print("Missing:")
        for item in report.missing:
            console.print(f"  {item}")
    if report.warnings:
        console.print("Warnings:")
        for item in report.warnings:
            console.print(f"  {item}")
    console.print("Does not establish:")
    for item in report.does_not_establish:
        console.print(f"  {item}")
    console.print(report.provenance.authority_boundary)


def _print_source_adapter_report(report) -> None:
    console.print("Agevidence Source Adapter Test")
    console.print(f"Adapter: {report.adapter}")
    console.print(f"Fixtures: {report.fixture_count}")
    console.print(f"Mapped: {report.mapped_count}")
    console.print(f"Structurally valid: {report.structurally_valid}")
    console.print(f"Provenance complete: {report.provenance_complete}")
    console.print(f"Provenance partial: {report.provenance_partial}")
    console.print(f"Provenance incomplete: {report.provenance_incomplete}")
    console.print(
        "No canonical schema extensions required."
        if report.no_canonical_schema_extensions_required
        else "Canonical schema extensions required."
    )
    if report.failures:
        console.print("Failures:")
        for failure in report.failures:
            console.print(f"  {failure}")
    console.print(report.authority_boundary)


def _print_proofkit_list(proofkits) -> None:
    console.print("AgEvidence Wave Proof Kits")
    for proofkit in proofkits:
        console.print(f"{proofkit.id:<48} {proofkit.generated_primitive:<20} {proofkit.domain_profile}")
    console.print("Local proofs use canonical primitives plus reusable domain profiles.")


def _print_proofkit_run(result) -> None:
    console.print("AgEvidence Wave Proof")
    console.print(f"Proof kit: {result.proof_id}")
    console.print(f"Company: {result.company}")
    console.print(f"Domain profile: {result.domain_profile}")
    console.print(f"Profile ID: {result.profile_id}")
    console.print(f"Generated primitive: {result.generated_primitive}")
    console.print(f"Native source record: {result.native_source_record}")
    console.print(f"Mapped primitives: {len(result.primitives)}")
    profile_status = ", ".join(item.get("status", "unknown").upper() for item in result.profile_applications)
    console.print(f"Profile application: {profile_status}")
    console.print(f"Source adapter passed: {str(result.adapter_report.get('passed')).upper()}")
    for index, digest in enumerate(result.local_digests, start=1):
        console.print(f"Local digest {index}: {digest}")
    if result.rust_validation:
        for item in result.rust_validation:
            console.print(f"Rust validate {item.schema_name}: {item.status.upper()}")
    if result.receipt_projections:
        for item in result.receipt_projections:
            console.print(f"Receipt projection {item.schema_name}: {item.status.upper()}")
        console.print("Receipt projections are delegated Rust outputs and are not production signatures.")
    console.print(result.authority_boundary)


def _print_profile_list(profiles) -> None:
    console.print("AgEvidence Domain Profiles")
    for profile in profiles:
        metadata = profile.metadata
        console.print(f"{metadata.profile_id:<52} {metadata.expected_primitive_type:<20} {metadata.name}")
    console.print("Profiles describe domain semantics above invariant core primitives.")


def _print_profile(profile) -> None:
    metadata = profile.metadata
    console.print("AgEvidence Domain Profile")
    console.print(f"Profile ID: {metadata.profile_id}")
    console.print(f"Name: {metadata.name}")
    console.print(f"Version: {metadata.version}")
    console.print(f"Family: {metadata.family}")
    console.print(f"Expected primitive: {metadata.expected_primitive_type}")
    if metadata.aliases:
        console.print(f"Aliases: {', '.join(metadata.aliases)}")
    if metadata.input_requirements:
        console.print("Input requirements:")
        for requirement in metadata.input_requirements:
            console.print(f"  {requirement}")
    if metadata.limitations:
        console.print("Limitations:")
        for limitation in metadata.limitations:
            console.print(f"  {limitation}")


if __name__ == "__main__":
    app()
