use anyhow::{Context, Result};
use axum::{
    extract::{Path as AxumPath, Query, State},
    http::{HeaderMap, StatusCode},
    routing::{get, post, put},
    Json, Router,
};
use chrono::Utc;
use clap::Parser;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use std::{
    collections::HashSet,
    fs,
    io::Read,
    path::{Component, Path, PathBuf},
    sync::Arc,
};
use tokio::{
    net::TcpListener,
    sync::{oneshot, Mutex},
};
use uuid::Uuid;
use walkdir::WalkDir;

const API_VERSION: &str = "v1";
const CORE_VERSION: &str = env!("CARGO_PKG_VERSION");
const MAX_EVIDENCE_PREVIEW: u64 = 1_048_576;
const MAX_SEARCH_FILE: u64 = 1_048_576;

#[derive(Parser, Debug)]
#[command(name = "divabyte-core")]
struct Args {
    #[arg(long)]
    data_root: PathBuf,
    #[arg(long)]
    runbook_root: PathBuf,
    #[arg(long)]
    report_root: PathBuf,
    #[arg(long)]
    connection_file: PathBuf,
    #[arg(long, default_value_t = 0)]
    port: u16,
}

struct AppState {
    data_root: PathBuf,
    runbook_root: PathBuf,
    report_root: PathBuf,
    token: String,
    research_mode: Mutex<String>,
    shutdown_tx: Mutex<Option<oneshot::Sender<()>>>,
}

type SharedState = Arc<AppState>;
type ApiError = (StatusCode, Json<Value>);
type ApiResult = std::result::Result<Json<Value>, ApiError>;

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct EvidenceRecord {
    id: String,
    path: String,
    sha256: String,
    size: u64,
    added_at: String,
    excerpt: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct CaseMessage {
    id: String,
    kind: String,
    text: String,
    created_at: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct Fact {
    id: String,
    claim: String,
    evidence_ids: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct Hypothesis {
    cause: String,
    confidence: String,
    supporting_evidence: Vec<String>,
    contradicting_evidence: Vec<String>,
    what_would_disprove_it: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct DiagnosticStep {
    tool: String,
    reason: String,
    risk: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct CaseRecord {
    id: String,
    title: String,
    created_at: String,
    updated_at: String,
    status: String,
    evidence: Vec<EvidenceRecord>,
    messages: Vec<CaseMessage>,
    corrections: Vec<CaseMessage>,
    facts: Vec<Fact>,
    hypotheses: Vec<Hypothesis>,
    unknowns: Vec<String>,
    next_diagnostics: Vec<DiagnosticStep>,
    memory_influence: Vec<SearchHit>,
    runbook_sources: Vec<SearchHit>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct MemoryRecord {
    id: String,
    created_at: String,
    entry_type: String,
    trust: String,
    title: String,
    body: String,
    source: String,
    evidence_ids: Vec<String>,
    research_sources: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct RunbookProposal {
    id: String,
    created_at: String,
    status: String,
    relative_path: String,
    title: String,
    content: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct SearchHit {
    path: String,
    title: String,
    excerpt: String,
    score: usize,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct CreateCaseInput {
    title: Option<String>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct EvidenceInput {
    path: String,
}

#[derive(Deserialize)]
struct TextInput {
    text: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct MemoryInput {
    #[serde(rename = "type")]
    entry_type: String,
    trust: String,
    title: String,
    body: String,
    source: Option<String>,
    evidence_ids: Option<Vec<String>>,
    research_sources: Option<Vec<String>>,
}

#[derive(Deserialize)]
struct SearchQuery {
    q: Option<String>,
}

#[derive(Deserialize)]
struct ResearchModeInput {
    mode: String,
}

#[derive(Deserialize)]
struct ResearchRequest {
    query: String,
    approved: Option<bool>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct ProposalInput {
    relative_path: String,
    title: String,
    content: String,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    for path in [
        args.data_root.join("Memory"),
        args.data_root.join("Cases"),
        args.data_root.join("ResearchCache"),
        args.data_root.join("RunbookProposals"),
        args.data_root.join("Sessions"),
    ] {
        fs::create_dir_all(&path)
            .with_context(|| format!("creating {}", path.display()))?;
    }
    fs::create_dir_all(&args.runbook_root)?;
    fs::create_dir_all(&args.report_root)?;
    if let Some(parent) = args.connection_file.parent() {
        fs::create_dir_all(parent)?;
    }

    let research_mode = load_research_mode(&args.data_root);
    let token = Uuid::new_v4().simple().to_string();
    let (shutdown_tx, shutdown_rx) = oneshot::channel();

    let state = Arc::new(AppState {
        data_root: args.data_root.clone(),
        runbook_root: args.runbook_root.clone(),
        report_root: args.report_root.clone(),
        token: token.clone(),
        research_mode: Mutex::new(research_mode),
        shutdown_tx: Mutex::new(Some(shutdown_tx)),
    });

    let app = Router::new()
        .route("/v1/health", get(health))
        .route("/v1/status", get(status))
        .route("/v1/shutdown", post(shutdown))
        .route("/v1/cases", post(create_case))
        .route("/v1/cases/{id}", get(get_case))
        .route("/v1/cases/{id}/evidence", post(add_evidence))
        .route("/v1/cases/{id}/message", post(add_message))
        .route("/v1/cases/{id}/correction", post(add_correction))
        .route("/v1/cases/{id}/analyze", post(analyze_case))
        .route("/v1/cases/{id}/hypotheses", get(get_hypotheses))
        .route("/v1/memory", post(add_memory))
        .route("/v1/memory/search", get(search_memory))
        .route("/v1/runbook/search", get(search_runbook))
        .route("/v1/runbook/proposals", post(create_runbook_proposal))
        .route("/v1/runbook/proposals/{id}/approve", post(approve_runbook_proposal))
        .route("/v1/research/mode", get(get_research_mode).put(set_research_mode))
        .route("/v1/research", post(research))
        .with_state(state.clone());

    let listener = TcpListener::bind(("127.0.0.1", args.port)).await?;
    let address = listener.local_addr()?;
    let connection = json!({
        "apiVersion": API_VERSION,
        "coreVersion": CORE_VERSION,
        "pid": std::process::id(),
        "host": "127.0.0.1",
        "port": address.port(),
        "token": token,
        "platform": std::env::consts::OS,
        "arch": std::env::consts::ARCH
    });
    write_json(&args.connection_file, &connection)?;

    println!("DIVABYTE_CORE_READY {}", connection);
    let server = axum::serve(listener, app).with_graceful_shutdown(async move {
        let _ = shutdown_rx.await;
    });
    let result = server.await;
    let _ = fs::remove_file(&args.connection_file);
    result?;
    Ok(())
}

async fn health() -> Json<Value> {
    Json(json!({
        "ok": true,
        "name": "DivaByte",
        "apiVersion": API_VERSION,
        "coreVersion": CORE_VERSION,
        "platform": std::env::consts::OS,
        "arch": std::env::consts::ARCH
    }))
}

async fn status(State(state): State<SharedState>, headers: HeaderMap) -> ApiResult {
    authorize(&headers, &state)?;
    let mode = state.research_mode.lock().await.clone();
    Ok(Json(json!({
        "ok": true,
        "apiVersion": API_VERSION,
        "coreVersion": CORE_VERSION,
        "platform": std::env::consts::OS,
        "arch": std::env::consts::ARCH,
        "researchMode": mode,
        "localModel": {
            "connected": false,
            "provider": "not-connected"
        },
        "internetResearch": {
            "connected": false,
            "provider": "not-connected"
        },
        "paths": {
            "dataRoot": state.data_root,
            "runbookRoot": state.runbook_root,
            "reportRoot": state.report_root
        },
        "counts": {
            "cases": count_extension(&state.data_root.join("Cases"), "json"),
            "memory": count_extension(&state.data_root.join("Memory"), "json"),
            "runbookArticles": count_runbook_articles(&state.runbook_root)
        }
    })))
}

async fn shutdown(State(state): State<SharedState>, headers: HeaderMap) -> ApiResult {
    authorize(&headers, &state)?;
    if let Some(tx) = state.shutdown_tx.lock().await.take() {
        let _ = tx.send(());
    }
    Ok(Json(json!({"ok": true, "message": "DivaByte core shutting down."})))
}

async fn create_case(
    State(state): State<SharedState>,
    headers: HeaderMap,
    Json(input): Json<CreateCaseInput>,
) -> ApiResult {
    authorize(&headers, &state)?;
    let now = Utc::now().to_rfc3339();
    let id = Uuid::new_v4().to_string();
    let title = input
        .title
        .filter(|v| !v.trim().is_empty())
        .unwrap_or_else(|| format!("Diagnostic Case {}", Utc::now().format("%Y-%m-%d %H:%M:%S UTC")));
    let case = CaseRecord {
        id: id.clone(),
        title,
        created_at: now.clone(),
        updated_at: now,
        status: "Open".to_string(),
        evidence: vec![],
        messages: vec![],
        corrections: vec![],
        facts: vec![],
        hypotheses: vec![],
        unknowns: vec![],
        next_diagnostics: vec![],
        memory_influence: vec![],
        runbook_sources: vec![],
    };
    save_case(&state, &case).map_err(internal_error)?;
    Ok(Json(json!(case)))
}

async fn get_case(
    State(state): State<SharedState>,
    headers: HeaderMap,
    AxumPath(id): AxumPath<String>,
) -> ApiResult {
    authorize(&headers, &state)?;
    let case = load_case(&state, &id)?;
    Ok(Json(json!(case)))
}

async fn add_evidence(
    State(state): State<SharedState>,
    headers: HeaderMap,
    AxumPath(id): AxumPath<String>,
    Json(input): Json<EvidenceInput>,
) -> ApiResult {
    authorize(&headers, &state)?;
    let mut case = load_case(&state, &id)?;
    let path = fs::canonicalize(&input.path)
        .map_err(|e| api_error(StatusCode::BAD_REQUEST, &format!("Evidence path is not readable: {e}")))?;
    let metadata = fs::metadata(&path)
        .map_err(|e| api_error(StatusCode::BAD_REQUEST, &format!("Evidence metadata failed: {e}")))?;
    if !metadata.is_file() {
        return Err(api_error(StatusCode::BAD_REQUEST, "Evidence must be a file."));
    }
    let sha256 = hash_file(&path).map_err(internal_error)?;
    if case.evidence.iter().any(|e| e.sha256 == sha256 && e.path == path.to_string_lossy()) {
        return Ok(Json(json!({"ok": true, "duplicate": true, "case": case})));
    }
    let excerpt = read_limited_text(&path, MAX_EVIDENCE_PREVIEW).map_err(internal_error)?;
    let record = EvidenceRecord {
        id: format!("EV-{}", Uuid::new_v4().simple()),
        path: path.to_string_lossy().to_string(),
        sha256,
        size: metadata.len(),
        added_at: Utc::now().to_rfc3339(),
        excerpt,
    };
    case.evidence.push(record.clone());
    case.updated_at = Utc::now().to_rfc3339();
    case.status = "Evidence Added".to_string();
    save_case(&state, &case).map_err(internal_error)?;
    Ok(Json(json!({"ok": true, "evidence": record, "caseId": case.id})))
}

async fn add_message(
    State(state): State<SharedState>,
    headers: HeaderMap,
    AxumPath(id): AxumPath<String>,
    Json(input): Json<TextInput>,
) -> ApiResult {
    authorize(&headers, &state)?;
    add_case_text(&state, &id, "Technician Message", &input.text, false)
}

async fn add_correction(
    State(state): State<SharedState>,
    headers: HeaderMap,
    AxumPath(id): AxumPath<String>,
    Json(input): Json<TextInput>,
) -> ApiResult {
    authorize(&headers, &state)?;
    add_case_text(&state, &id, "Technician Correction", &input.text, true)
}

async fn get_hypotheses(
    State(state): State<SharedState>,
    headers: HeaderMap,
    AxumPath(id): AxumPath<String>,
) -> ApiResult {
    authorize(&headers, &state)?;
    let case = load_case(&state, &id)?;
    Ok(Json(json!({
        "caseId": case.id,
        "hypotheses": case.hypotheses,
        "unknowns": case.unknowns,
        "nextDiagnostics": case.next_diagnostics
    })))
}

async fn analyze_case(
    State(state): State<SharedState>,
    headers: HeaderMap,
    AxumPath(id): AxumPath<String>,
) -> ApiResult {
    authorize(&headers, &state)?;
    let mut case = load_case(&state, &id)?;
    let mut facts = Vec::new();
    let mut fact_counter = 0usize;

    for evidence in &case.evidence {
        for line in evidence.excerpt.lines() {
            let trimmed = line.trim();
            if trimmed.is_empty() || !looks_diagnostic(trimmed) {
                continue;
            }
            fact_counter += 1;
            facts.push(Fact {
                id: format!("E{fact_counter}"),
                claim: trimmed.chars().take(500).collect(),
                evidence_ids: vec![evidence.id.clone()],
            });
            if facts.len() >= 30 {
                break;
            }
        }
        if facts.len() >= 30 {
            break;
        }
    }

    let combined = facts
        .iter()
        .map(|f| f.claim.to_lowercase())
        .collect::<Vec<_>>()
        .join("\n");

    let mut hypotheses = Vec::new();
    maybe_add_hypothesis(
        &mut hypotheses,
        &facts,
        &combined,
        "Network path, DNS, or connectivity interruption",
        &["timeout", "timed out", "dns", "unreachable", "connection reset", "tns-12170", "tns-12535", "network"],
        &["connected", "reachable", "dns succeeded", "success"],
        "Run a focused network/DNS diagnostic and correlate client/server timestamps.",
    );
    maybe_add_hypothesis(
        &mut hypotheses,
        &facts,
        &combined,
        "Authentication, certificate, or access-control failure",
        &["authentication", "802.1x", "radius", "certificate", "access denied", "unauthorized", "logon failure", "eap"],
        &["authentication succeeded", "authorized", "certificate valid"],
        "Collect authentication/certificate events and verify the identity method in use.",
    );
    maybe_add_hypothesis(
        &mut hypotheses,
        &facts,
        &combined,
        "Storage, filesystem, or I/O problem",
        &["disk", "i/o", "io error", "filesystem", "ntfs", "apfs", "smart", "bad block", "corrupt"],
        &["disk healthy", "filesystem healthy", "no errors found"],
        "Run storage health and filesystem diagnostics before attempting repair.",
    );
    maybe_add_hypothesis(
        &mut hypotheses,
        &facts,
        &combined,
        "Application or service failure",
        &["service", "crash", "exception", "faulting", "stopped", "terminated", "application error"],
        &["service running", "healthy", "started successfully"],
        "Inspect service/application events immediately before and after the failure.",
    );

    if hypotheses.is_empty() {
        hypotheses.push(Hypothesis {
            cause: "Insufficient evidence to identify a root-cause family".to_string(),
            confidence: "Low".to_string(),
            supporting_evidence: facts.iter().take(3).map(|f| f.id.clone()).collect(),
            contradicting_evidence: vec![],
            what_would_disprove_it: vec![
                "Additional evidence that clearly identifies a failing subsystem.".to_string(),
            ],
        });
    }

    let search_seed = build_search_seed(&facts);
    let memory_hits = search_memory_internal(&state.data_root.join("Memory"), &search_seed, 5);
    let runbook_hits = search_runbook_internal(&state.runbook_root, &search_seed, 5);

    let mut next_diagnostics = Vec::new();
    for hypothesis in &hypotheses {
        let reason = if hypothesis.cause.contains("Network") {
            "Collect IP, DNS, route, adapter, and recent network-event evidence."
        } else if hypothesis.cause.contains("Authentication") {
            "Collect authentication, certificate, WLAN/NPS, or access-control evidence."
        } else if hypothesis.cause.contains("Storage") {
            "Collect disk health, filesystem, and recent I/O event evidence."
        } else if hypothesis.cause.contains("Application") {
            "Collect service state plus application/system events around the incident time."
        } else {
            "Collect a broader diagnostic snapshot so competing hypotheses can be separated."
        };
        next_diagnostics.push(DiagnosticStep {
            tool: "Field Kit diagnostic appropriate to this hypothesis".to_string(),
            reason: reason.to_string(),
            risk: "ReadOnly".to_string(),
        });
    }

    let mut unknowns = Vec::new();
    if case.evidence.is_empty() {
        unknowns.push("No evidence files have been attached to this case.".to_string());
    }
    unknowns.push(
        "The local LLM provider is not connected in this build; this analysis is deterministic and evidence-driven only."
            .to_string(),
    );
    if !case.corrections.is_empty() {
        unknowns.push(
            "Technician corrections are present and should be treated as constraints during the next model-assisted analysis."
                .to_string(),
        );
    }

    case.facts = facts;
    case.hypotheses = hypotheses;
    case.unknowns = unknowns;
    case.next_diagnostics = next_diagnostics;
    case.memory_influence = memory_hits;
    case.runbook_sources = runbook_hits;
    case.status = "Analyzed".to_string();
    case.updated_at = Utc::now().to_rfc3339();
    save_case(&state, &case).map_err(internal_error)?;

    Ok(Json(json!({
        "incidentSummary": format!("DivaByte analyzed {} evidence file(s) and extracted {} diagnostic fact(s).", case.evidence.len(), case.facts.len()),
        "caseId": case.id,
        "status": case.status,
        "facts": case.facts,
        "hypotheses": case.hypotheses,
        "unknowns": case.unknowns,
        "nextDiagnostics": case.next_diagnostics,
        "memoryInfluence": case.memory_influence,
        "runbookSources": case.runbook_sources,
        "externalResearch": [],
        "analysisEngine": "deterministic-core-v1",
        "modelConnected": false
    })))
}

async fn add_memory(
    State(state): State<SharedState>,
    headers: HeaderMap,
    Json(input): Json<MemoryInput>,
) -> ApiResult {
    authorize(&headers, &state)?;
    if input.title.trim().is_empty() || input.body.trim().is_empty() {
        return Err(api_error(StatusCode::BAD_REQUEST, "Memory title and body are required."));
    }
    let record = MemoryRecord {
        id: Uuid::new_v4().simple().to_string(),
        created_at: Utc::now().to_rfc3339(),
        entry_type: input.entry_type,
        trust: input.trust,
        title: input.title.trim().to_string(),
        body: input.body.trim().to_string(),
        source: input.source.unwrap_or_else(|| "Technician".to_string()),
        evidence_ids: input.evidence_ids.unwrap_or_default(),
        research_sources: input.research_sources.unwrap_or_default(),
    };
    let path = state
        .data_root
        .join("Memory")
        .join(format!("{}-{}.json", Utc::now().format("%Y%m%d-%H%M%S-%3f"), record.id));
    write_json(&path, &record).map_err(internal_error)?;
    Ok(Json(json!({"ok": true, "memory": record})))
}

async fn search_memory(
    State(state): State<SharedState>,
    headers: HeaderMap,
    Query(query): Query<SearchQuery>,
) -> ApiResult {
    authorize(&headers, &state)?;
    let q = query.q.unwrap_or_default();
    let hits = search_memory_internal(&state.data_root.join("Memory"), &q, 20);
    Ok(Json(json!({"query": q, "results": hits})))
}

async fn search_runbook(
    State(state): State<SharedState>,
    headers: HeaderMap,
    Query(query): Query<SearchQuery>,
) -> ApiResult {
    authorize(&headers, &state)?;
    let q = query.q.unwrap_or_default();
    let hits = search_runbook_internal(&state.runbook_root, &q, 20);
    Ok(Json(json!({"query": q, "results": hits})))
}

async fn create_runbook_proposal(
    State(state): State<SharedState>,
    headers: HeaderMap,
    Json(input): Json<ProposalInput>,
) -> ApiResult {
    authorize(&headers, &state)?;
    if !safe_relative_path(&input.relative_path) {
        return Err(api_error(StatusCode::BAD_REQUEST, "Runbook proposal path must be a safe relative path."));
    }
    let proposal = RunbookProposal {
        id: Uuid::new_v4().simple().to_string(),
        created_at: Utc::now().to_rfc3339(),
        status: "Pending Technician Approval".to_string(),
        relative_path: input.relative_path,
        title: input.title,
        content: input.content,
    };
    let path = state
        .data_root
        .join("RunbookProposals")
        .join(format!("{}.json", proposal.id));
    write_json(&path, &proposal).map_err(internal_error)?;
    Ok(Json(json!({"ok": true, "proposal": proposal, "runbookModified": false})))
}

async fn approve_runbook_proposal(
    State(state): State<SharedState>,
    headers: HeaderMap,
    AxumPath(id): AxumPath<String>,
) -> ApiResult {
    authorize(&headers, &state)?;
    validate_uuidish(&id)?;
    let proposal_path = state.data_root.join("RunbookProposals").join(format!("{id}.json"));
    let mut proposal: RunbookProposal = read_json(&proposal_path).map_err(|_| {
        api_error(StatusCode::NOT_FOUND, "Runbook proposal was not found.")
    })?;
    if !safe_relative_path(&proposal.relative_path) {
        return Err(api_error(StatusCode::BAD_REQUEST, "Stored proposal path is invalid."));
    }
    let destination = state.runbook_root.join(&proposal.relative_path);
    if let Some(parent) = destination.parent() {
        fs::create_dir_all(parent).map_err(internal_error)?;
    }
    fs::write(&destination, proposal.content.as_bytes()).map_err(internal_error)?;
    proposal.status = "Approved and Applied".to_string();
    write_json(&proposal_path, &proposal).map_err(internal_error)?;
    Ok(Json(json!({
        "ok": true,
        "proposal": proposal,
        "runbookModified": true,
        "path": destination
    })))
}

async fn get_research_mode(State(state): State<SharedState>, headers: HeaderMap) -> ApiResult {
    authorize(&headers, &state)?;
    let mode = state.research_mode.lock().await.clone();
    Ok(Json(json!({"mode": mode})))
}

async fn set_research_mode(
    State(state): State<SharedState>,
    headers: HeaderMap,
    Json(input): Json<ResearchModeInput>,
) -> ApiResult {
    authorize(&headers, &state)?;
    if !valid_research_mode(&input.mode) {
        return Err(api_error(StatusCode::BAD_REQUEST, "Unsupported research mode."));
    }
    *state.research_mode.lock().await = input.mode.clone();
    fs::write(state.data_root.join("Research-Mode.txt"), input.mode.as_bytes())
        .map_err(internal_error)?;
    Ok(Json(json!({"ok": true, "mode": input.mode})))
}

async fn research(
    State(state): State<SharedState>,
    headers: HeaderMap,
    Json(input): Json<ResearchRequest>,
) -> ApiResult {
    authorize(&headers, &state)?;
    let mode = state.research_mode.lock().await.clone();
    if mode == "Offline" {
        return Err(api_error(
            StatusCode::FORBIDDEN,
            "DivaByte is in Offline mode. No Internet request was made.",
        ));
    }
    if mode == "Ask Before Researching" && input.approved != Some(true) {
        return Err((
            StatusCode::CONFLICT,
            Json(json!({
                "ok": false,
                "approvalRequired": true,
                "mode": mode,
                "query": input.query,
                "message": "Technician approval is required before Internet research."
            })),
        ));
    }

    let record = json!({
        "id": Uuid::new_v4().simple().to_string(),
        "createdAt": Utc::now().to_rfc3339(),
        "query": input.query,
        "mode": mode,
        "status": "Research provider not connected",
        "internetRequestMade": false
    });
    let path = state
        .data_root
        .join("ResearchCache")
        .join(format!("request-{}.json", Utc::now().format("%Y%m%d-%H%M%S-%3f")));
    write_json(&path, &record).map_err(internal_error)?;
    Err((
        StatusCode::NOT_IMPLEMENTED,
        Json(json!({
            "ok": false,
            "internetRequestMade": false,
            "message": "Research policy is active, but the live Internet research provider is not connected in this build.",
            "request": record
        })),
    ))
}

fn add_case_text(state: &AppState, id: &str, kind: &str, text: &str, correction: bool) -> ApiResult {
    if text.trim().is_empty() {
        return Err(api_error(StatusCode::BAD_REQUEST, "Text is required."));
    }
    let mut case = load_case(state, id)?;
    let item = CaseMessage {
        id: Uuid::new_v4().simple().to_string(),
        kind: kind.to_string(),
        text: text.trim().to_string(),
        created_at: Utc::now().to_rfc3339(),
    };
    if correction {
        case.corrections.push(item.clone());
        case.status = "Needs Re-evaluation".to_string();
    } else {
        case.messages.push(item.clone());
    }
    case.updated_at = Utc::now().to_rfc3339();
    save_case(state, &case).map_err(internal_error)?;
    Ok(Json(json!({"ok": true, "entry": item, "case": case})))
}

fn save_case(state: &AppState, case: &CaseRecord) -> Result<()> {
    let path = state.data_root.join("Cases").join(format!("{}.json", case.id));
    write_json(&path, case)
}

fn load_case(state: &AppState, id: &str) -> std::result::Result<CaseRecord, ApiError> {
    validate_uuidish(id)?;
    let path = state.data_root.join("Cases").join(format!("{id}.json"));
    read_json(&path).map_err(|_| api_error(StatusCode::NOT_FOUND, "Diagnostic case was not found."))
}

fn validate_uuidish(value: &str) -> std::result::Result<(), ApiError> {
    if Uuid::parse_str(value).is_ok() || (value.len() == 32 && value.chars().all(|c| c.is_ascii_hexdigit())) {
        Ok(())
    } else {
        Err(api_error(StatusCode::BAD_REQUEST, "Invalid identifier."))
    }
}

fn authorize(headers: &HeaderMap, state: &AppState) -> std::result::Result<(), ApiError> {
    let expected = format!("Bearer {}", state.token);
    let actual = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .unwrap_or_default();
    if actual == expected {
        Ok(())
    } else {
        Err(api_error(StatusCode::UNAUTHORIZED, "Invalid or missing DivaByte session token."))
    }
}

fn api_error(status: StatusCode, message: &str) -> ApiError {
    (status, Json(json!({"ok": false, "message": message})))
}

fn internal_error<E: std::fmt::Display>(error: E) -> ApiError {
    api_error(StatusCode::INTERNAL_SERVER_ERROR, &error.to_string())
}

fn write_json<T: Serialize>(path: &Path, value: &T) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let text = serde_json::to_string_pretty(value)?;
    fs::write(path, text.as_bytes())?;
    Ok(())
}

fn read_json<T: for<'de> Deserialize<'de>>(path: &Path) -> Result<T> {
    let text = fs::read_to_string(path)?;
    Ok(serde_json::from_str(&text)?)
}

fn hash_file(path: &Path) -> Result<String> {
    let mut file = fs::File::open(path)?;
    let mut hasher = Sha256::new();
    let mut buffer = [0u8; 64 * 1024];
    loop {
        let n = file.read(&mut buffer)?;
        if n == 0 {
            break;
        }
        hasher.update(&buffer[..n]);
    }
    Ok(format!("{:x}", hasher.finalize()))
}

fn read_limited_text(path: &Path, max_bytes: u64) -> Result<String> {
    let file = fs::File::open(path)?;
    let mut bytes = Vec::new();
    file.take(max_bytes).read_to_end(&mut bytes)?;
    Ok(String::from_utf8_lossy(&bytes).to_string())
}

fn looks_diagnostic(line: &str) -> bool {
    let lower = line.to_lowercase();
    [
        "error",
        "fail",
        "critical",
        "exception",
        "timeout",
        "timed out",
        "denied",
        "unhealthy",
        "warning",
        "warn",
        "tns-",
        "ora-",
        "event id",
        "fault",
        "corrupt",
        "unreachable",
    ]
    .iter()
    .any(|needle| lower.contains(needle))
}

fn maybe_add_hypothesis(
    hypotheses: &mut Vec<Hypothesis>,
    facts: &[Fact],
    combined: &str,
    cause: &str,
    supporting_terms: &[&str],
    contradicting_terms: &[&str],
    disprove: &str,
) {
    let matched_support: Vec<String> = facts
        .iter()
        .filter(|fact| {
            let lower = fact.claim.to_lowercase();
            supporting_terms.iter().any(|term| lower.contains(term))
        })
        .map(|f| f.id.clone())
        .collect();
    if matched_support.is_empty() {
        return;
    }
    let matched_contra: Vec<String> = facts
        .iter()
        .filter(|fact| {
            let lower = fact.claim.to_lowercase();
            contradicting_terms.iter().any(|term| lower.contains(term))
        })
        .map(|f| f.id.clone())
        .collect();
    let confidence = if matched_support.len() >= 3 && matched_contra.is_empty() {
        "High"
    } else if matched_support.len() >= 2 {
        "Medium"
    } else {
        "Low"
    };
    let _ = combined;
    hypotheses.push(Hypothesis {
        cause: cause.to_string(),
        confidence: confidence.to_string(),
        supporting_evidence: matched_support,
        contradicting_evidence: matched_contra,
        what_would_disprove_it: vec![disprove.to_string()],
    });
}

fn build_search_seed(facts: &[Fact]) -> String {
    let mut words = Vec::new();
    let mut seen = HashSet::new();
    for fact in facts.iter().take(15) {
        for word in tokenize(&fact.claim) {
            if word.len() >= 4 && seen.insert(word.clone()) {
                words.push(word);
            }
            if words.len() >= 20 {
                return words.join(" ");
            }
        }
    }
    words.join(" ")
}

fn tokenize(text: &str) -> Vec<String> {
    text.to_lowercase()
        .split(|c: char| !c.is_alphanumeric() && c != '-' && c != '_')
        .filter(|s| s.len() >= 3)
        .map(|s| s.to_string())
        .collect()
}

fn score_text(text: &str, query: &str) -> usize {
    let lower = text.to_lowercase();
    tokenize(query)
        .into_iter()
        .map(|term| lower.matches(&term).count())
        .sum()
}

fn search_memory_internal(root: &Path, query: &str, limit: usize) -> Vec<SearchHit> {
    if query.trim().is_empty() {
        return vec![];
    }
    let mut hits = Vec::new();
    let Ok(entries) = fs::read_dir(root) else {
        return hits;
    };
    for entry in entries.flatten() {
        if entry.path().extension().and_then(|e| e.to_str()) != Some("json") {
            continue;
        }
        let Ok(text) = fs::read_to_string(entry.path()) else {
            continue;
        };
        let score = score_text(&text, query);
        if score == 0 {
            continue;
        }
        let title = serde_json::from_str::<Value>(&text)
            .ok()
            .and_then(|v| v.get("title").and_then(Value::as_str).map(str::to_string))
            .unwrap_or_else(|| entry.file_name().to_string_lossy().to_string());
        hits.push(SearchHit {
            path: entry.path().to_string_lossy().to_string(),
            title,
            excerpt: text.chars().take(500).collect(),
            score,
        });
    }
    hits.sort_by(|a, b| b.score.cmp(&a.score));
    hits.truncate(limit);
    hits
}

fn search_runbook_internal(root: &Path, query: &str, limit: usize) -> Vec<SearchHit> {
    if query.trim().is_empty() {
        return vec![];
    }
    let mut hits = Vec::new();
    for entry in WalkDir::new(root).into_iter().flatten() {
        if !entry.file_type().is_file() {
            continue;
        }
        let path = entry.path();
        let ext = path.extension().and_then(|e| e.to_str()).unwrap_or_default().to_lowercase();
        if ext != "md" && ext != "txt" {
            continue;
        }
        let Ok(meta) = fs::metadata(path) else {
            continue;
        };
        if meta.len() > MAX_SEARCH_FILE {
            continue;
        }
        let Ok(text) = fs::read_to_string(path) else {
            continue;
        };
        let score = score_text(&text, query);
        if score == 0 {
            continue;
        }
        let title = text
            .lines()
            .find(|line| line.trim_start().starts_with('#'))
            .map(|line| line.trim_start_matches('#').trim().to_string())
            .filter(|v| !v.is_empty())
            .unwrap_or_else(|| entry.file_name().to_string_lossy().to_string());
        let relative = path.strip_prefix(root).unwrap_or(path).to_string_lossy().to_string();
        hits.push(SearchHit {
            path: relative,
            title,
            excerpt: text.chars().take(700).collect(),
            score,
        });
    }
    hits.sort_by(|a, b| b.score.cmp(&a.score));
    hits.truncate(limit);
    hits
}

fn safe_relative_path(value: &str) -> bool {
    let path = Path::new(value);
    if path.as_os_str().is_empty() || path.is_absolute() {
        return false;
    }
    !path.components().any(|component| {
        matches!(component, Component::ParentDir | Component::RootDir | Component::Prefix(_))
    })
}

fn valid_research_mode(mode: &str) -> bool {
    matches!(mode, "Offline" | "Local + Research" | "Ask Before Researching")
}

fn load_research_mode(root: &Path) -> String {
    let path = root.join("Research-Mode.txt");
    let mode = fs::read_to_string(path).unwrap_or_else(|_| "Ask Before Researching".to_string());
    let trimmed = mode.trim();
    if valid_research_mode(trimmed) {
        trimmed.to_string()
    } else {
        "Ask Before Researching".to_string()
    }
}

fn count_extension(root: &Path, extension: &str) -> usize {
    fs::read_dir(root)
        .map(|entries| {
            entries
                .flatten()
                .filter(|entry| entry.path().extension().and_then(|e| e.to_str()) == Some(extension))
                .count()
        })
        .unwrap_or(0)
}

fn count_runbook_articles(root: &Path) -> usize {
    WalkDir::new(root)
        .into_iter()
        .flatten()
        .filter(|entry| {
            entry.file_type().is_file()
                && matches!(
                    entry.path().extension().and_then(|e| e.to_str()),
                    Some("md") | Some("txt")
                )
        })
        .count()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn research_modes_are_strict() {
        assert!(valid_research_mode("Offline"));
        assert!(valid_research_mode("Local + Research"));
        assert!(valid_research_mode("Ask Before Researching"));
        assert!(!valid_research_mode("Online"));
    }

    #[test]
    fn runbook_paths_must_be_relative_and_safe() {
        assert!(safe_relative_path("Network/WiFi.md"));
        assert!(!safe_relative_path("../outside.md"));
        assert!(!safe_relative_path("/tmp/outside.md"));
    }

    #[test]
    fn diagnostic_lines_are_detected() {
        assert!(looks_diagnostic("ERROR TNS-12170 connection timed out"));
        assert!(looks_diagnostic("Warning: disk I/O error"));
        assert!(!looks_diagnostic("Normal status report"));
    }
}
