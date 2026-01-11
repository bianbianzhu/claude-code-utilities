# Agent Benchmarks and Standard Evaluations

This document covers the major benchmarks used to evaluate LLM agents, what each measures, and how to use them effectively for capability assessment.

## Benchmark Landscape Overview

| Benchmark | Focus Area | Environment | Metric Type | Difficulty |
|-----------|-----------|-------------|-------------|------------|
| **GAIA** | Tool use + Reasoning | Question answering | Task completion | Multi-level |
| **AgentBench** | General agent capability | 8 environments | Success rate | Varied |
| **WebArena** | Web navigation | 4 realistic domains | Functional correctness | High |
| **SWE-bench** | Software engineering | GitHub issues | Patch correctness | High |
| **ToolBench** | API/Tool mastery | 16,000+ APIs | Tool use accuracy | Varied |
| **Terminal-Bench** | CLI operations | Sandboxed terminal | Multi-step workflows | High |
| **Context-Bench** | Long context reasoning | File operations | Consistency | High |
| **DPAI Arena** | Developer productivity | Multi-language | Full lifecycle | High |

---

## GAIA (General AI Assistants)

**Overview**: GAIA tests tool-use and reasoning in answering questions that seem simple for humans but require AI to use tools or combine modalities.

### What It Measures
- Multi-step reasoning ability
- Tool selection and usage
- Cross-modal reasoning (text, images, calculations)
- Real-world problem decomposition

### Difficulty Levels

| Level | Description | Example Skills Required |
|-------|-------------|------------------------|
| **Level 1** | Basic tool use | Single tool, few steps |
| **Level 2** | Multi-tool coordination | Multiple tools, moderate reasoning |
| **Level 3** | Complex reasoning chains | Many steps, advanced integration |

### Task Examples
- "What is the population of the capital of the country where the Eiffel Tower is located?"
- Image analysis combined with calculation
- Multi-source information synthesis

### How to Use

```python
# GAIA evaluation example (conceptual)
from gaia_benchmark import GAIAEvaluator

evaluator = GAIAEvaluator()
results = evaluator.evaluate(
    agent=my_agent,
    levels=[1, 2, 3],  # Evaluate all difficulty levels
    tools=["search", "calculator", "image_analysis"]
)

print(f"Level 1 accuracy: {results.level1_score}")
print(f"Level 2 accuracy: {results.level2_score}")
print(f"Level 3 accuracy: {results.level3_score}")
```

### Key Insights
- Tests generalizable reasoning, not memorized knowledge
- Highlights gaps in multi-step planning
- Good for comparing tool-augmented vs. base models

---

## AgentBench

**Overview**: The first comprehensive benchmark designed to evaluate LLM-as-Agent across a diverse spectrum of different environments.

### What It Measures
- Autonomous agent capability
- Environment adaptation
- Long-term reasoning and planning
- Decision-making under uncertainty

### Environments (8 Total)

| Environment | Type | Description |
|-------------|------|-------------|
| **Operating System** | Interactive | File system and shell operations |
| **Database** | Interactive | SQL query generation and execution |
| **Knowledge Graph** | Interactive | Graph traversal and querying |
| **Digital Card Game** | Game | Strategic decision-making |
| **Lateral Thinking Puzzles** | Reasoning | Creative problem solving |
| **House-Holding** | Simulation | Domestic task planning |
| **Web Shopping** | Web | E-commerce navigation |
| **Web Browsing** | Web | General web interaction |

### Key Findings from Research
- Poor long-term reasoning is a main obstacle for usable LLM agents
- Decision-making quality degrades over multi-step workflows
- Instruction following ability varies significantly across models

### How to Use

```bash
# Clone AgentBench repository
git clone https://github.com/THUDM/AgentBench.git
cd AgentBench

# Install dependencies
pip install -r requirements.txt

# Run evaluation on specific environment
python eval.py --agent your_agent --env os --model gpt-4
```

### Metrics
- **Success Rate**: Percentage of tasks completed correctly
- **Progress Rate**: Partial completion tracking
- **Step Efficiency**: Average steps to completion

### Key Insights
- Exposes fundamental weaknesses in autonomous operation
- Useful for comparing base models before agent scaffolding
- Highlights importance of environment-specific training

---

## WebArena

**Overview**: A self-hosted benchmark and environment for autonomous agents performing web tasks across realistic domains.

### What It Measures
- Web navigation capability
- Form filling and interaction
- Multi-page workflows
- Real-world web task completion

### Domains (4 Realistic Scenarios)

| Domain | Description | Example Tasks |
|--------|-------------|---------------|
| **E-commerce** | Online shopping site | Search, compare, purchase |
| **Social Forums** | Reddit-like platform | Post, comment, navigate |
| **Collaborative Code** | GitLab-like platform | Create issues, PRs, review |
| **Content Management** | CMS/Wiki system | Create, edit, organize content |

### Task Characteristics
- 812 templated tasks with variations
- Functional correctness evaluation (goal-based, not path-based)
- Multi-step workflows requiring planning

### Evaluation Criteria
- **Success**: Agent achieves the final goal
- **Path-Independent**: Any valid approach accepted
- **Functional Verification**: Automated goal checking

### How to Use

```bash
# Setup WebArena environment
docker-compose up -d  # Start all domain containers

# Run agent evaluation
python run_agent.py \
    --agent your_agent \
    --task_file tasks/shopping.json \
    --output_dir results/
```

### Key Insights
- Exposes gaps in visual understanding (many agents fail on layout)
- Multi-step planning is a major challenge
- Error recovery is often weak

---

## SWE-bench

**Overview**: SWE-bench tests agents on real-world GitHub issues, measuring software engineering capability through actual patch generation.

### What It Measures
- Code understanding at repository scale
- Bug localization
- Patch generation accuracy
- Test-passing capability

### Variants

| Variant | Size | Description |
|---------|------|-------------|
| **SWE-bench Full** | 2,294 issues | Complete benchmark |
| **SWE-bench Lite** | 300 issues | Curated subset for faster evaluation |
| **SWE-bench Verified** | ~500 issues | Human-verified subset (most reliable) |

### Scoring
- **Resolved Rate**: Percentage of issues with passing patches
- Patches must pass repository's test suite
- No partial credit (binary success/failure)

### State-of-the-Art (2025)

| Model | SWE-bench Verified Score |
|-------|-------------------------|
| Claude Opus 4.5 | 80.9% |
| Claude Sonnet 4.5 | 77.2% (avg) / 82.0% (high compute) |
| GPT 5.1 | 76.3% |
| Gemini 3 Pro | 76.2% |

### How to Use

```python
# SWE-bench evaluation setup
from swebench import SWEbench

benchmark = SWEbench(variant="verified")

for issue in benchmark.issues:
    # Agent generates patch
    patch = agent.solve(
        repo=issue.repo,
        issue_text=issue.description,
        test_file=issue.test_file
    )

    # Evaluate patch
    result = benchmark.evaluate(issue.id, patch)
    print(f"Issue {issue.id}: {'PASS' if result.passed else 'FAIL'}")
```

### Key Insights
- Measures software engineering, not general autonomy
- High bar for production-ready coding agents
- Context window and retrieval critical for large repos

---

## ToolBench

**Overview**: A massive-scale benchmark for evaluating LLMs on 16,000+ real-world RESTful APIs, focusing on tool mastery and API usage.

### What It Measures
- API selection from large catalogs
- Parameter construction
- Multi-API orchestration
- Error handling and recovery

### Dataset Characteristics
- 16,000+ real-world RESTful APIs
- Automatically generated using ChatGPT
- Instruction-tuning focused

### API Categories
- Weather, finance, social media
- E-commerce, travel, utilities
- Government, health, entertainment

### Evaluation Metrics

| Metric | Description |
|--------|-------------|
| **Pass Rate** | Successful API call completion |
| **Win Rate** | Comparison against baseline |
| **API Accuracy** | Correct API selection |
| **Parameter Accuracy** | Correct parameter construction |

### How to Use

```python
from toolbench import ToolBenchEvaluator

evaluator = ToolBenchEvaluator(
    api_catalog="real_world_apis.json",
    test_cases="tool_use_cases.json"
)

results = evaluator.evaluate(agent=my_agent)
print(f"Pass Rate: {results.pass_rate}")
print(f"API Selection Accuracy: {results.api_accuracy}")
```

### Key Insights
- Exposes tool-use brittleness in production scenarios
- API documentation comprehension is critical
- Error recovery often determines success

---

## Emerging Benchmarks (2025)

### Terminal-Bench

**Released**: May 2025 (Stanford + Laude Institute)

**Focus**: Command-line agent capability in sandboxed environments

**What It Measures**:
- Multi-step workflow execution
- Plan-execute-recover cycles
- Shell command proficiency
- Error recovery in CLI

**Key Differentiator**: Unlike one-shot benchmarks, measures sustained operation across workflows.

### Context-Bench

**Released**: October 2025 (Letta)

**Focus**: Long-running context maintenance and reasoning

**What It Measures**:
- File operation chaining
- Relationship tracing across project structures
- Consistent decision-making over extended workflows
- Memory and context utilization

**Key Differentiator**: Tests what defines modern agent systems - context persistence.

### DPAI Arena (Developer Productivity AI Arena)

**Released**: October 2025 (JetBrains)

**Focus**: Full engineering lifecycle across languages

**What It Measures**:
- Multi-language proficiency
- End-to-end developer workflows
- IDE integration capability
- Beyond issue-to-patch (full lifecycle)

**Key Differentiator**: Evaluates complete developer agent, not just code generation.

---

## Specialized Benchmarks

### OSWorld

**Focus**: Operating system interaction

**Current Leaders** (2025):
- Claude Sonnet 4.5: 61.4%
- Previous leader (Claude Sonnet 4): 42.2%

### AgentHarm

**Focus**: Safety and robustness

**Coverage**:
- 11 harm categories
- Attack and defense evaluation
- Jailbreak resistance testing

### MedAgentBench

**Focus**: Medical domain agents

**Features**:
- Clinically-derived tasks
- Realistic medical data
- Domain-specific evaluation

---

## How to Choose Benchmarks

### Decision Framework

```
What capability are you measuring?
├── General autonomy → AgentBench
├── Web interaction → WebArena
├── Software engineering → SWE-bench
├── Tool/API usage → ToolBench
├── Reasoning + tools → GAIA
├── CLI/Terminal → Terminal-Bench
└── Long context → Context-Bench
```

### Recommended Combinations

| Agent Type | Primary Benchmark | Secondary |
|------------|------------------|-----------|
| **General Purpose** | AgentBench | GAIA |
| **Web Agent** | WebArena | AgentBench (web subset) |
| **Coding Agent** | SWE-bench | Terminal-Bench |
| **API/Tool Agent** | ToolBench | GAIA |
| **Full-Stack Dev** | SWE-bench | DPAI Arena |

### Evaluation Best Practices

1. **Use multiple benchmarks**: No single benchmark captures all capabilities
2. **Interpret carefully**: High benchmark scores don't guarantee production readiness
3. **Consider your domain**: General benchmarks may miss domain-specific weaknesses
4. **Track over time**: Benchmark on each major change
5. **Combine with custom evals**: Benchmarks complement but don't replace application-specific testing

---

## Benchmark Limitations

### Common Pitfalls

| Issue | Description | Mitigation |
|-------|-------------|------------|
| **Overfitting** | Models trained on benchmark data | Use held-out or dynamic benchmarks |
| **Distribution Shift** | Benchmark tasks differ from production | Add domain-specific evaluation |
| **Single Metric** | Success rate hides nuance | Track multiple metrics |
| **Static Nature** | Benchmarks become outdated | Use evolving benchmarks |
| **Leakage** | Test data in training sets | Verify data provenance |

### What Benchmarks Don't Measure

- **Cost efficiency**: Token usage and latency
- **User experience**: Subjective quality
- **Safety in production**: Edge cases and adversarial inputs
- **Reliability**: Consistency across runs
- **Recovery**: Graceful failure handling

### Complementary Approaches

1. **Red teaming**: For safety evaluation (see [Methodologies](./methodologies.md))
2. **Production monitoring**: Real-world performance tracking
3. **Human evaluation**: For subjective quality
4. **Custom test suites**: Domain-specific requirements

---

## Resources

### Official Repositories

- **AgentBench**: https://github.com/THUDM/AgentBench
- **WebArena**: https://github.com/web-arena-x/webarena
- **SWE-bench**: https://github.com/princeton-nlp/SWE-bench
- **ToolBench**: https://github.com/OpenBMB/ToolBench
- **GAIA**: https://huggingface.co/gaia-benchmark

### Leaderboards

- **SWE-bench**: https://www.swebench.com/
- **AgentBench**: https://llmbench.ai/agent
- **GAIA**: Hugging Face Spaces

### Benchmark Compendium

For a comprehensive list of 50+ agent benchmarks, see:
https://github.com/philschmid/ai-agent-benchmark-compendium

---

*See also: [Methodologies](./methodologies.md) | [Building Your Own](./building-your-own.md)*
