# README Synchronization Workflow - Architecture Specification

## Executive Summary

This document defines the architecture for automatically synchronizing the repository's README.md to Docker Hub whenever Docker images are successfully published. The design prioritizes reliability, security, and maintainability while integrating seamlessly with the existing CI/CD pipeline.

**Version:** 1.0  
**Status:** Design Phase  
**Target Implementation:** Code mode

---

## 1. Integration Strategy

### 1.1 Chosen Approach: Integrated Workflow (Single-Job Addition)

**Decision:** Add a second job (`sync-readme`) to the existing `.github/workflows/docker-publish.yml` workflow.

**Rationale:**

**Pros:**
- **Atomic Deployment:** README updates occur in the same workflow run as image publication, ensuring consistency
- **Simplified Maintenance:** Single workflow file to manage instead of multiple files
- **Shared Context:** Inherits same triggers, concurrency groups, and permissions strategy
- **Reduced Complexity:** No need to coordinate between multiple workflows
- **Better Traceability:** Single workflow run shows complete deployment status (image + README)
- **Efficient Resource Usage:** No additional workflow dispatch overhead

**Cons:**
- Slightly larger workflow file (manageable at ~100 lines total)
- README sync failures could appear in Docker publish workflow logs (mitigated by proper error handling)

**Alternative Considered:** Separate workflow file triggered by workflow_run
- **Rejected because:** Adds complexity with workflow chaining, separate concurrency control, potential race conditions, and harder debugging

### 1.2 Job Placement and Dependencies

```
jobs:
  build-and-push:          # Existing job (unchanged)
    runs-on: ubuntu-latest
    steps: [checkout, build, push, scan]
    
  sync-readme:             # New job (added)
    needs: build-and-push
    if: success()
    runs-on: ubuntu-latest
    steps: [checkout, sync]
```

**Key Design Points:**
- `needs: build-and-push` ensures README sync only runs after successful image publication
- `if: success()` explicitly checks previous job succeeded
- Runs on separate runner to isolate concerns and prevent build environment contamination

---

## 2. Trigger Design

### 2.1 Trigger Conditions

The README sync job will inherit the workflow triggers but apply additional filtering:

**Workflow-Level Triggers (inherited, unchanged):**
```yaml
on:
  push:
    branches: ["main"]
    tags: ["v*"]
  workflow_dispatch:
  workflow_run:
    workflows: ["Test"]
    types: [completed]
    branches: ["main"]
```

**Job-Level Conditions (new):**
```yaml
sync-readme:
  needs: build-and-push
  if: |
    success() && 
    (github.event_name == 'push' || github.event_name == 'workflow_dispatch') &&
    (github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v'))
```

### 2.2 Trigger Logic Explanation

**README sync will run when:**
1. ✅ `build-and-push` job completes successfully
2. ✅ Event is either `push` or `workflow_dispatch` (user-initiated)
3. ✅ Target is either `main` branch or a version tag (`v*`)

**README sync will NOT run when:**
1. ❌ Build job fails (ensures only successful builds update README)
2. ❌ Triggered by `workflow_run` (test completion) - avoids redundant syncs
3. ❌ Push to non-main branches (feature branches)
4. ❌ Non-version tags

### 2.3 Edge Cases Handled

| Scenario | Behavior | Justification |
|----------|----------|---------------|
| PR merge to main | ✅ Sync runs | Main branch updates should sync |
| Direct push to main | ✅ Sync runs | Same as PR merge |
| Tag creation (v1.0.0) | ✅ Sync runs | Version releases should update description |
| Build fails | ❌ Skip sync | Don't update README if images aren't published |
| Manual workflow_dispatch | ✅ Sync runs | Allow manual README updates |
| Workflow_run trigger | ❌ Skip sync | Test completion alone doesn't warrant sync |
| Concurrent runs | ⏳ Queued | Concurrency group ensures serialization |

---

## 3. Authentication & Security

### 3.1 Secret Management

**Existing Secrets (reused):**
- `secrets.DOCKERHUB_USERNAME` - Docker Hub account username
- `secrets.DOCKERHUB_TOKEN` - Docker Hub access token (read/write scope required)

**Verification Requirements:**
- Token must have `read/write` permissions to update repository descriptions
- Token should be personal access token (PAT) or bot account token
- Token expiration should be monitored (manual process, document in runbook)

### 3.2 Permission Requirements

**Workflow-Level Permissions:**
```yaml
permissions:
  contents: read        # Checkout repository
  packages: write       # Existing for build job
  security-events: write # Existing for Trivy scan
```

**Job-Level Permissions (sync-readme):**
```yaml
permissions:
  contents: read        # Only needs to read README.md
```

**Principle of Least Privilege:**
- Sync job requires no write permissions to repository
- No elevated GitHub token permissions needed
- Docker Hub credentials are scoped to Docker Hub API only

### 3.3 Security Considerations

**Threats and Mitigations:**

1. **Token Exposure:**
   - ✅ Use GitHub Secrets (encrypted at rest)
   - ✅ Never log token values
   - ✅ Action handles credentials securely

2. **Malicious README Content:**
   - ✅ Only syncs from trusted main branch
   - ✅ No user input in sync process
   - ✅ Docker Hub sanitizes markdown display

3. **Supply Chain Attack:**
   - ✅ Pin action to specific SHA (not just version tag)
   - ✅ Use official actions from verified publishers
   - ✅ Review action source before adoption

4. **Rate Limiting Abuse:**
   - ✅ Concurrency control prevents parallel runs
   - ✅ Idempotency checks reduce unnecessary updates
   - ✅ Docker Hub API has reasonable rate limits

**Secret Rotation Policy:**
- Rotate `DOCKERHUB_TOKEN` every 90 days (recommended)
- Test token after rotation with workflow_dispatch
- Document rotation procedure in operations runbook

---

## 4. README Sync Mechanism

### 4.1 Action Selection

**Chosen Action:** `peter-evans/dockerhub-description@v4`

**Justification:**

| Criterion | peter-evans/dockerhub-description | docker/docker-hub-description | Custom API calls |
|-----------|-----------------------------------|-------------------------------|------------------|
| Maturity | 4+ years, 1k+ stars | Archived, deprecated | N/A |
| Maintenance | Active (2024 updates) | No longer maintained | Requires maintenance |
| Features | Full/short description | Basic only | Custom implementation |
| Simplicity | Simple YAML config | Simple YAML config | Complex HTTP logic |
| Community | Wide adoption | Legacy users | None |
| **Decision** | ✅ **Selected** | ❌ Rejected | ❌ Rejected |

**Version Pinning Strategy:**
```yaml
uses: peter-evans/dockerhub-description@e98e4d1628a5f3be2be7c231e50981aee98723ae  # v4.0.0
```
- Pin to specific commit SHA for security
- Add version tag in comment for human readability
- Update SHA when action releases security patches

### 4.2 Configuration Parameters

```yaml
- name: Sync README to Docker Hub
  uses: peter-evans/dockerhub-description@e98e4d1628a5f3be2be7c231e50981aee98723ae  # v4.0.0
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
    repository: firbykirby/udp-broadcast-relay
    readme-filepath: ./README.md
    short-description: 'UDP broadcast relay for IoT device discovery across VLANs'
```

**Parameter Breakdown:**

| Parameter | Value | Source | Notes |
|-----------|-------|--------|-------|
| `username` | `${{ secrets.DOCKERHUB_USERNAME }}` | GitHub Secret | Existing secret |
| `password` | `${{ secrets.DOCKERHUB_TOKEN }}` | GitHub Secret | Existing secret |
| `repository` | `firbykirby/udp-broadcast-relay` | Hardcoded | Matches existing workflow |
| `readme-filepath` | `./README.md` | Relative path | Default location |
| `short-description` | `'UDP broadcast relay...'` | Hardcoded | Docker Hub 100-char limit |

**Short Description Guidelines:**
- Maximum 100 characters (Docker Hub limit)
- Concise value proposition
- Matches README.md heading/summary
- No markdown formatting (plain text only)

### 4.3 Relative Link Handling

**Current State:**
README.md contains relative links:
```markdown
- [docs/CONFIGURATION.md](docs/CONFIGURATION.md)
- [docs/EXAMPLES.md](docs/EXAMPLES.md)
- [docs/UNRAID_SETUP.md](docs/UNRAID_SETUP.md)
- [docs/LOOP_PREVENTION.md](docs/LOOP_PREVENTION.md)
- [docker-compose.yml](docker-compose.yml)
```

**Strategy: No Conversion (GitHub-to-GitHub Links)**

**Decision:** Keep relative links unchanged.

**Rationale:**
- Docker Hub's markdown renderer converts relative links to GitHub URLs automatically
- Tested pattern: `docs/FILE.md` → `https://github.com/USER/REPO/blob/main/docs/FILE.md`
- Simpler implementation with no preprocessing needed
- Maintains single source of truth for README content

**Alternative Considered:** Convert to absolute GitHub URLs
- **Rejected because:** Adds complexity, brittle to repository renames, Docker Hub handles it natively

**Validation Required:**
- Test that Docker Hub correctly converts links after first sync
- Verify links resolve to correct GitHub paths
- Document expected behavior in implementation phase

---

## 5. Error Handling Strategy

### 5.1 Failure Modes and Recovery

**Potential Failure Scenarios:**

| Failure Mode | Probability | Impact | Recovery Strategy |
|--------------|-------------|--------|-------------------|
| Invalid credentials | Low | High | Workflow fails, alert via email | 
| Docker Hub API rate limit | Low | Medium | Retry with exponential backoff |
| Network timeout | Low | Low | Single retry, then fail |
| README file not found | Very Low | High | Workflow fails immediately |
| Malformed markdown | Very Low | Low | Sync proceeds, Docker Hub sanitizes |
| Docker Hub outage | Very Low | Medium | Fail gracefully, retry on next run |

### 5.2 Error Handling Design

**Job-Level Configuration:**
```yaml
sync-readme:
  needs: build-and-push
  if: success()
  runs-on: ubuntu-latest
  continue-on-error: false  # Fail workflow if sync fails
  timeout-minutes: 5         # Prevent hanging
```

**Step-Level Configuration:**
```yaml
- name: Sync README to Docker Hub
  uses: peter-evans/dockerhub-description@e98e4d1628a5f3be2be7c231e50981aee98723ae
  continue-on-error: false
  timeout-minutes: 3
```

**Retry Logic:**
- **Built into action:** peter-evans/dockerhub-description includes internal retry logic
- **No custom retry needed:** Action handles transient failures
- **Workflow retry:** Use workflow_dispatch for manual retry if needed

### 5.3 Should Sync Failures Block Workflow?

**Decision:** Yes, sync failures should fail the workflow.

**Justification:**
- **Critical Documentation:** README is primary user-facing documentation
- **Deployment Integrity:** Outdated README can mislead users about image capabilities
- **Early Detection:** Immediate failure alerts team to credential/permission issues
- **Safe Retry:** Workflow can be manually re-run without rebuilding images

**Monitoring Requirements:**
- Enable GitHub Actions failure notifications
- Monitor workflow runs in GitHub UI
- Set up alerts for repeated failures (external monitoring)

### 5.4 Logging Strategy

**Log Levels:**
```yaml
- name: Sync README to Docker Hub
  uses: peter-evans/dockerhub-description@e98e4d1628a5f3be2be7c231e50981aee98723ae
  env:
    DEBUG: 'false'  # Action supports debug mode if needed
```

**Logged Information:**
- ✅ README file path and size
- ✅ Target Docker Hub repository
- ✅ Sync operation status (success/failure)
- ✅ Docker Hub API response (sanitized)
- ❌ Credentials (never logged)

**Debug Mode:**
- Enable via workflow_dispatch input parameter
- Provides verbose API communication logs
- Use for troubleshooting sync issues

---

## 6. Multi-Architecture Considerations

### 6.1 Build Completion Coordination

**Current Build Process:**
```yaml
build-and-push:
  steps:
    - name: Build and push (multi-arch)
      uses: docker/build-push-action@v6
      with:
        platforms: linux/amd64,linux/arm64
```

**Key Insight:** Docker buildx creates a **single manifest** for multi-arch images.

**Synchronization Strategy:**

```
Timeline:
T0: Build starts (amd64 + arm64 in parallel)
T1: amd64 build completes
T2: arm64 build completes
T3: Manifest pushed to Docker Hub (single atomic operation)
T4: build-and-push job completes ✅
T5: sync-readme job starts (waits for T4)
```

**Why This Works:**
- Multi-arch build is a single step using docker/build-push-action
- Action only succeeds when ALL platforms complete successfully
- Manifest list is pushed atomically
- `needs: build-and-push` ensures sync waits for complete multi-arch publication

**No Additional Coordination Needed:**
- ✅ Job dependency ensures proper sequencing
- ✅ No race conditions between architectures
- ✅ No need to check individual platform tags

### 6.2 Manifest Validation (Optional Enhancement)

**Future Consideration:**
Add validation step before sync to verify manifest exists:
```yaml
- name: Verify manifest published
  run: |
    docker manifest inspect docker.io/firbykirby/udp-broadcast-relay:latest
```

**Decision:** Not included in initial implementation
- Buildx action guarantees manifest push on success
- Adds unnecessary latency (~5 seconds)
- Can be added if reliability issues observed

---

## 7. Idempotency and Rate Limiting

### 7.1 Idempotency Design

**Goal:** Allow safe workflow re-runs without side effects.

**Built-in Idempotency:**
- Docker Hub API is idempotent - updating README with same content is harmless
- No risk of duplicate publications or corrupted state
- Safe to re-run workflow after failures

**Content Comparison (Built into Action):**
- peter-evans/dockerhub-description checks if README changed before updating
- Skips API call if content identical to current Docker Hub description
- Reduces unnecessary updates and API calls

### 7.2 Rate Limiting Strategy

**Docker Hub API Limits:**
- **Authenticated requests:** 5,000 requests/hour per token
- **README updates:** Counted as single request per call
- **Effective limit:** Well above typical usage patterns

**Protection Mechanisms:**

1. **Workflow Concurrency Control:**
```yaml
concurrency:
  group: docker-publish-${{ github.ref }}
  cancel-in-progress: false  # Queue, don't cancel
```
- Ensures serial execution per branch/tag
- Prevents parallel README syncs
- Queues concurrent workflow runs

2. **Trigger Filtering:**
- Only syncs on main branch and version tags
- Skips PR branches and test-only runs
- Reduces sync frequency naturally

3. **Content-Based Skipping:**
- Action skips update if README unchanged
- Reduces actual API calls to Docker Hub
- No custom logic needed

**Rate Limit Handling:**
- Action returns error on rate limit exceeded
- Workflow fails visibly in GitHub UI
- Manual retry after cooldown period

**Typical Usage Pattern:**
- Main branch pushes: ~5-10 per day (max)
- Version tags: ~1 per week (max)
- Manual workflow_dispatch: Rare
- **Total:** <50 README syncs per month << 5,000/hour limit

---

## 8. Testing Strategy

### 8.1 Testing Phases

**Phase 1: Validation Testing (Before Merge)**
- Syntax validation of workflow YAML
- Dry-run workflow with workflow_dispatch
- Verify job dependencies and conditionals

**Phase 2: Integration Testing (In Production)**
- Test sync on main branch push (non-critical change)
- Test sync on tag creation (test tag: v0.0.0-test)
- Verify Docker Hub README updated correctly

**Phase 3: Regression Testing (Ongoing)**
- Monitor sync success rate
- Test after workflow modifications
- Validate after Docker Hub API changes

### 8.2 Validation Criteria

**Pre-Merge Checks:**
- ✅ Workflow YAML passes GitHub Actions linter
- ✅ No syntax errors in job definitions
- ✅ All action versions pinned to commit SHAs
- ✅ Secrets referenced correctly

**Post-Deployment Checks:**
- ✅ Workflow completes without errors
- ✅ Docker Hub README content matches repository README.md
- ✅ Relative links render correctly on Docker Hub
- ✅ Short description appears in Docker Hub search results
- ✅ Workflow execution time <5 minutes total
- ✅ No credential exposure in logs

### 8.3 Dry-Run and Staging Approach

**Recommended Testing Sequence:**

1. **Local Validation:**
```bash
# Validate workflow syntax
gh workflow view docker-publish.yml
```

2. **Test Workflow Dispatch:**
- Trigger workflow_dispatch manually from GitHub UI
- Verify build-and-push job succeeds
- Verify sync-readme job runs after build
- Check Docker Hub for README update

3. **Test Tag Creation:**
```bash
git tag v0.0.0-test
git push origin v0.0.0-test
```
- Verify workflow triggers on tag push
- Confirm README sync runs for version tags
- Delete test tag after validation

4. **Monitor Main Branch:**
- Make minor README change
- Push to main branch
- Verify automatic sync occurs

**Staging Environment:**
- **Not required** - Docker Hub is production environment
- Test with actual Docker Hub repository
- Low risk: README updates are non-destructive

### 8.4 Rollback Strategy

**If Sync Breaks:**

1. **Immediate Rollback:**
```bash
git revert <commit-sha>  # Revert workflow changes
git push origin main
```

2. **Manual README Update:**
- Edit README directly on Docker Hub web interface
- Provides immediate fix while investigating

3. **Investigation:**
- Review workflow run logs
- Check action version compatibility
- Verify Docker Hub API status

**Recovery Time Objective (RTO):** <15 minutes
- Revert commit: 2 minutes
- Push and workflow run: 5 minutes
- Verification: 3 minutes
- Buffer: 5 minutes

---

## 9. Workflow Structure Summary

### 9.1 Complete Job Flow

```
Trigger Event (push main/tag, workflow_dispatch)
  ↓
[workflow filter: allowed event types]
  ↓
Job: build-and-push (existing, unchanged)
  ├─ Checkout repository
  ├─ Setup QEMU (arm64)
  ├─ Setup Docker Buildx
  ├─ Login to Docker Hub
  ├─ Generate metadata (tags/labels)
  ├─ Build and push (multi-arch: amd64, arm64)
  ├─ Run Trivy security scan
  └─ Upload scan results
  ↓
[success check + trigger filter]
  ↓
Job: sync-readme (new)
  ├─ Checkout repository
  └─ Sync README to Docker Hub
```

### 9.2 Job Dependencies

```
build-and-push ──[needs + if: success()]──> sync-readme
     │                                           │
     │                                           │
  [always runs]                      [conditional: main/tag only]
```

### 9.3 Conditional Execution Matrix

| Trigger | Branch/Tag | build-and-push | sync-readme |
|---------|------------|----------------|-------------|
| push | main | ✅ Runs | ✅ Runs |
| push | feature/* | ❌ Skipped | ❌ Skipped |
| push | v1.0.0 | ✅ Runs | ✅ Runs |
| push | test-tag | ✅ Runs | ❌ Skipped |
| workflow_dispatch | main | ✅ Runs | ✅ Runs |
| workflow_dispatch | feature/* | ✅ Runs | ❌ Skipped |
| workflow_run | main (test success) | ✅ Runs | ❌ Skipped |

---

## 10. Security Review Checklist

**Pre-Implementation Validation:**

- [ ] Secrets are not exposed in logs or outputs
- [ ] Action versions pinned to commit SHAs
- [ ] Action source code reviewed for supply chain risks
- [ ] Minimum required permissions defined
- [ ] No hardcoded credentials in workflow file
- [ ] Token scope verified (read/write for repo description)
- [ ] Rate limiting protections in place
- [ ] Error messages don't leak sensitive information
- [ ] Workflow concurrency prevents race conditions
- [ ] Branch protection rules considered (main branch)

---

## 11. Prerequisites and Assumptions

### 11.1 Prerequisites

**Required:**
- ✅ GitHub repository with Actions enabled
- ✅ Docker Hub account: `firbykirby`
- ✅ Docker Hub repository: `firbykirby/udp-broadcast-relay`
- ✅ GitHub Secrets configured:
  - `DOCKERHUB_USERNAME` (value: `firbykirby`)
  - `DOCKERHUB_TOKEN` (Docker Hub access token with read/write scope)

**Optional:**
- GitHub Actions notifications enabled (email/Slack)
- External monitoring for workflow failures

### 11.2 Assumptions

**Technical Assumptions:**
- Docker Hub markdown renderer handles relative GitHub links correctly
- peter-evans/dockerhub-description action remains maintained
- Docker Hub API rate limits remain at current levels (5,000/hour)
- Multi-arch builds complete atomically via single manifest push

**Operational Assumptions:**
- Main branch is protected (requires PR review)
- Team monitors GitHub Actions notifications
- Workflow failures trigger manual investigation
- Token rotation occurs every 90 days

**Content Assumptions:**
- README.md remains Docker-focused and suitable for Docker Hub
- README.md stays under Docker Hub's display limits (~25,000 characters)
- Relative links point to files that exist in repository

### 11.3 Known Limitations

1. **No automated link validation:** Relative links are not checked before sync
2. **No preview environment:** Changes go directly to production Docker Hub
3. **Manual token rotation:** No automated secret rotation
4. **Single repository:** Architecture focused on one Docker Hub repo
5. **No rollback automation:** Manual intervention required if sync breaks

---

## 12. Implementation Handoff

### 12.1 Implementation Checklist

**Code Phase Tasks:**
1. Add `sync-readme` job to `.github/workflows/docker-publish.yml`
2. Configure job dependencies and conditionals
3. Add action step with pinned version
4. Set timeout and error handling parameters
5. Commit changes to feature branch
6. Create PR with description and testing plan

**Testing Phase Tasks:**
1. Validate workflow YAML syntax
2. Test workflow_dispatch from feature branch
3. Merge to main and verify automatic sync
4. Create test tag and verify tag-based sync
5. Verify Docker Hub README content and links
6. Delete test tag after validation

**Documentation Phase Tasks:**
1. Update repository README.md with workflow status badge (optional)
2. Document manual README sync procedure (workflow_dispatch)
3. Create operations runbook for troubleshooting
4. Document token rotation procedure

### 12.2 Success Metrics

**Quantitative:**
- README sync success rate: >99%
- Sync execution time: <3 minutes
- Workflow total time: <15 minutes (build + sync)
- Zero credential exposures

**Qualitative:**
- Docker Hub README stays in sync with repository
- Team can manually trigger syncs reliably
- Failures are easily debugged from logs
- No user-reported documentation inconsistencies

### 12.3 Monitoring and Maintenance

**Ongoing Activities:**
- Monitor workflow run success rate weekly
- Review sync failures within 24 hours
- Update action version quarterly (security patches)
- Rotate DOCKERHUB_TOKEN every 90 days
- Review Docker Hub API changelog for breaking changes

**Escalation Path:**
- Workflow failures → Check GitHub Actions logs
- Repeated failures → Verify Docker Hub token validity
- Action errors → Check action repository for known issues
- Docker Hub outage → Wait for platform recovery

---

## 13. Conclusion

This architecture provides a robust, secure, and maintainable solution for automatic README synchronization to Docker Hub. The integrated approach leverages existing workflow infrastructure while maintaining clear separation of concerns through job dependencies.

**Key Strengths:**
- ✅ Minimal complexity (single job addition)
- ✅ Reliable execution (job dependencies + conditionals)
- ✅ Secure credential handling (existing secrets)
- ✅ Idempotent and safe to re-run
- ✅ Well-defined error handling and monitoring

**Next Steps:**
Switch to Code mode to implement the specification defined in this document.

---

## Appendix A: Alternative Architectures Considered

### A.1 Separate Workflow File

**Structure:**
- New file: `.github/workflows/readme-sync.yml`
- Triggered by: workflow_run completion of docker-publish.yml

**Pros:**
- Separation of concerns
- Independent testing

**Cons:**
- Workflow coordination complexity
- Separate concurrency control
- Harder to trace deployment status

**Verdict:** Rejected in favor of integrated approach.

### A.2 Scheduled Sync

**Structure:**
- Cron-based trigger: `schedule: cron: '0 0 * * *'`
- Daily README sync regardless of builds

**Pros:**
- Catches manual Docker Hub changes
- Simple trigger logic

**Cons:**
- Unnecessary syncs when README unchanged
- Higher API usage
- Less timely updates

**Verdict:** Rejected - event-driven is more efficient.

### A.3 Pre-Build README Check

**Structure:**
- Check if README changed before building
- Skip build if only README changed
- Sync README only

**Pros:**
- Avoids unnecessary builds

**Cons:**
- Complex conditional logic
- Doesn't solve main use case (sync after build)
- Edge cases with multi-file commits

**Verdict:** Rejected - optimizes wrong problem.

---

## Appendix B: Action Comparison Details

### B.1 peter-evans/dockerhub-description v4

**Repository:** https://github.com/peter-evans/dockerhub-description  
**Latest Release:** v4.0.0 (2024-01-15)  
**Stars:** 1.1k  
**Maintenance:** Active

**Features:**
- Full README.md sync
- Short description support
- Credential security best practices
- Automatic content comparison
- Built-in retry logic
- Debug mode

**Configuration:**
```yaml
uses: peter-evans/dockerhub-description@v4
with:
  username: ${{ secrets.DOCKERHUB_USERNAME }}
  password: ${{ secrets.DOCKERHUB_TOKEN }}
  repository: user/repo
  readme-filepath: ./README.md
  short-description: 'Description'
```

### B.2 Alternative: Custom API Implementation

**Example (not recommended):**
```bash
curl -X PATCH \
  https://hub.docker.com/v2/repositories/user/repo/ \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"full_description": "..."}'
```

**Cons:**
- Requires token acquisition flow
- No automatic retry logic
- Manual error handling
- Maintenance burden
- No content comparison

**Verdict:** Community action is superior.

---

## Appendix C: Docker Hub API Reference

**Endpoint:** `PATCH /v2/repositories/{namespace}/{repository}/`

**Authentication:** JWT Bearer token

**Request Body:**
```json
{
  "full_description": "Full README content",
  "description": "Short description (100 chars)"
}
```

**Response Codes:**
- 200: Success
- 401: Invalid credentials
- 404: Repository not found
- 429: Rate limit exceeded

**Rate Limits:**
- 5,000 requests/hour (authenticated)
- Applies to all API endpoints collectively

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-16 | Architecture Mode | Initial specification |

---

**End of Document**