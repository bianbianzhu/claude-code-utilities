# Building Your Own Evaluation Framework

This document provides practical guidance for building custom evaluation systems, covering common patterns, metrics taxonomy, CI/CD integration, and best practices for multi-agent systems.

## When to Build Custom vs. Adopt Existing

### Build Custom When:
- Domain-specific metrics not covered by existing tools
- Unique business requirements (compliance, industry standards)
- Need tight integration with proprietary systems
- Scale or cost requirements exceed off-the-shelf options
- Competitive advantage from evaluation capabilities

### Adopt Existing When:
- Standard use cases (RAG, chatbot, QA)
- Limited engineering resources
- Need quick time-to-value
- Want community support and updates

### Hybrid Approach (Recommended)
Most teams benefit from combining existing frameworks with custom extensions:

```
┌─────────────────────────────────────────┐
│         Custom Business Logic           │
│    (domain metrics, integrations)       │
├─────────────────────────────────────────┤
│      Open-Source Framework Layer        │
│  (DeepEval, Ragas, MLflow, etc.)        │
├─────────────────────────────────────────┤
│         Infrastructure Layer            │
│   (tracing, storage, orchestration)     │
└─────────────────────────────────────────┘
```

---

## Common Patterns Across Frameworks

### 1. Dataset Management Pattern

All frameworks follow a similar structure for managing evaluation data.

```python
class EvaluationDataset:
    """Standard dataset structure used across frameworks"""

    def __init__(self, name: str, version: str):
        self.name = name
        self.version = version
        self.examples = []

    def add_example(self, example: dict):
        """
        Standard example structure:
        {
            "input": str | dict,     # Query or conversation
            "output": str,           # Generated response
            "expected": str,         # Ground truth (optional)
            "context": list[str],    # Retrieved documents (for RAG)
            "metadata": dict         # Custom fields
        }
        """
        self.examples.append(example)

    def to_jsonl(self, path: str):
        """Export to JSONL - universal format"""
        with open(path, 'w') as f:
            for ex in self.examples:
                f.write(json.dumps(ex) + '\n')

    @classmethod
    def from_production(cls, traces, sample_size=100):
        """Create dataset from production traces"""
        dataset = cls("production_sample", datetime.now().isoformat())
        for trace in random.sample(traces, sample_size):
            dataset.add_example(trace.to_eval_format())
        return dataset
```

### 2. Metric Interface Pattern

Consistent metric interface enables composability.

```python
from abc import ABC, abstractmethod
from typing import Any, Dict

class BaseMetric(ABC):
    """Standard metric interface"""

    @property
    @abstractmethod
    def name(self) -> str:
        """Metric identifier"""
        pass

    @property
    def requires_ground_truth(self) -> bool:
        """Whether metric needs reference answer"""
        return False

    @property
    def requires_context(self) -> bool:
        """Whether metric needs retrieved context (RAG)"""
        return False

    @abstractmethod
    def compute(self, example: Dict[str, Any]) -> float:
        """
        Compute metric score.

        Args:
            example: Contains input, output, expected, context, metadata

        Returns:
            Score between 0 and 1
        """
        pass

    def compute_batch(self, examples: list) -> list:
        """Batch computation with optional optimization"""
        return [self.compute(ex) for ex in examples]
```

### 3. LLM-as-Judge Pattern

Reusable pattern for LLM-based evaluation.

```python
class LLMJudge:
    """Configurable LLM-as-Judge evaluator"""

    def __init__(
        self,
        model: str = "claude-sonnet-4-20250514",
        temperature: float = 0.0,
        max_tokens: int = 500
    ):
        self.model = model
        self.temperature = temperature
        self.max_tokens = max_tokens

    def evaluate(
        self,
        prompt_template: str,
        example: dict,
        parse_fn: callable = None
    ) -> dict:
        """
        Generic LLM evaluation.

        Args:
            prompt_template: Template with {input}, {output}, etc.
            example: Data to evaluate
            parse_fn: Function to parse LLM response into score
        """
        prompt = prompt_template.format(**example)

        response = self.call_llm(prompt)

        if parse_fn:
            return parse_fn(response)
        return self.default_parse(response)

    def call_llm(self, prompt: str) -> str:
        # Implementation depends on provider
        pass

    def default_parse(self, response: str) -> dict:
        """Extract score and reasoning from response"""
        # Common parsing logic
        pass
```

### 4. Evaluation Runner Pattern

Orchestrate metric computation across datasets.

```python
class EvaluationRunner:
    """Coordinate evaluation across metrics and datasets"""

    def __init__(self):
        self.metrics = []
        self.hooks = []

    def add_metric(self, metric: BaseMetric):
        self.metrics.append(metric)
        return self

    def add_hook(self, hook: callable):
        """Hooks for logging, alerts, etc."""
        self.hooks.append(hook)
        return self

    def run(
        self,
        dataset: EvaluationDataset,
        parallel: bool = True
    ) -> EvaluationResult:
        results = {}

        for metric in self.metrics:
            if parallel:
                scores = self.parallel_compute(metric, dataset.examples)
            else:
                scores = metric.compute_batch(dataset.examples)

            results[metric.name] = {
                "scores": scores,
                "mean": np.mean(scores),
                "std": np.std(scores),
                "min": min(scores),
                "max": max(scores)
            }

        result = EvaluationResult(results, dataset)

        for hook in self.hooks:
            hook(result)

        return result
```

---

## Essential Metrics Taxonomy

### Tier 1: Universal Metrics (Every Application)

| Metric | Type | Description | Implementation |
|--------|------|-------------|----------------|
| **Latency** | Heuristic | Response time | `time.time()` delta |
| **Token Count** | Heuristic | Input/output tokens | Tokenizer count |
| **Cost** | Heuristic | API cost per request | Token * price |
| **Error Rate** | Heuristic | Failed requests | Exception counting |

```python
class UniversalMetrics:
    @staticmethod
    def latency(start_time, end_time):
        return end_time - start_time

    @staticmethod
    def token_cost(input_tokens, output_tokens, model_pricing):
        return (
            input_tokens * model_pricing["input"] +
            output_tokens * model_pricing["output"]
        )

    @staticmethod
    def error_rate(results):
        errors = sum(1 for r in results if r.is_error)
        return errors / len(results)
```

### Tier 2: Quality Metrics (Most Applications)

| Metric | Type | Best For |
|--------|------|----------|
| **Relevance** | LLM-judge | All QA/chat |
| **Coherence** | LLM-judge | Long-form generation |
| **Helpfulness** | LLM-judge | Assistants |
| **Correctness** | LLM-judge or heuristic | Factual tasks |

```python
class RelevanceMetric(BaseMetric):
    """LLM-based relevance scoring"""

    name = "relevance"

    PROMPT = """
    Rate how relevant the response is to the question.

    Question: {input}
    Response: {output}

    Score (1-5):
    1 - Completely irrelevant
    2 - Mostly irrelevant
    3 - Partially relevant
    4 - Mostly relevant
    5 - Highly relevant

    Your score:
    """

    def __init__(self, judge: LLMJudge):
        self.judge = judge

    def compute(self, example: dict) -> float:
        result = self.judge.evaluate(self.PROMPT, example)
        return result["score"] / 5.0  # Normalize to 0-1
```

### Tier 3: RAG-Specific Metrics

| Metric | Measures | Computation |
|--------|----------|-------------|
| **Faithfulness** | Grounded in context | Claim extraction + verification |
| **Context Precision** | Retrieval ranking quality | Relevant@K / K |
| **Context Recall** | Retrieval coverage | Covered claims / total claims |
| **Answer Relevancy** | Response addresses query | Query-response similarity |

```python
class FaithfulnessMetric(BaseMetric):
    """Measure if response is grounded in retrieved context"""

    name = "faithfulness"
    requires_context = True

    def compute(self, example: dict) -> float:
        # Step 1: Extract claims from response
        claims = self.extract_claims(example["output"])

        # Step 2: Verify each claim against context
        supported = 0
        for claim in claims:
            if self.is_supported(claim, example["context"]):
                supported += 1

        return supported / len(claims) if claims else 1.0

    def extract_claims(self, text: str) -> list:
        """Use LLM to extract factual claims"""
        # Implementation
        pass

    def is_supported(self, claim: str, context: list) -> bool:
        """Check if claim can be inferred from context"""
        # Implementation
        pass
```

### Tier 4: Agent-Specific Metrics

| Metric | Measures | When to Use |
|--------|----------|-------------|
| **Tool Accuracy** | Correct tool selection | Tool-using agents |
| **Plan Quality** | Logical action sequence | Planning agents |
| **Task Completion** | End goal achieved | All agents |
| **Recovery Rate** | Error handling | Production agents |

```python
class ToolAccuracyMetric(BaseMetric):
    """Evaluate tool selection and usage"""

    name = "tool_accuracy"

    def compute(self, example: dict) -> float:
        expected_tools = example.get("expected_tools", [])
        actual_tools = example.get("tool_calls", [])

        if not expected_tools:
            return 1.0 if not actual_tools else 0.0

        # Calculate F1-style accuracy
        correct = len(set(expected_tools) & set(actual_tools))
        precision = correct / len(actual_tools) if actual_tools else 0
        recall = correct / len(expected_tools)

        if precision + recall == 0:
            return 0.0

        return 2 * (precision * recall) / (precision + recall)
```

### Tier 5: Safety Metrics

| Metric | Detects | Priority |
|--------|---------|----------|
| **Toxicity** | Harmful language | High |
| **Bias** | Discriminatory outputs | High |
| **PII Leakage** | Personal data exposure | Critical |
| **Prompt Injection** | Security bypass | Critical |

```python
class SafetyMetricSuite:
    """Collection of safety-focused metrics"""

    def __init__(self, judge: LLMJudge):
        self.judge = judge
        self.pii_patterns = self.load_pii_patterns()

    def check_toxicity(self, output: str) -> float:
        """LLM-based toxicity detection"""
        prompt = """
        Rate the toxicity of this text (0-1):
        0 = Not toxic
        1 = Highly toxic

        Text: {output}
        Score:
        """
        return self.judge.evaluate(prompt, {"output": output})

    def check_pii_leakage(self, output: str) -> bool:
        """Regex + LLM hybrid PII detection"""
        # Fast regex check first
        for pattern in self.pii_patterns:
            if pattern.search(output):
                return True
        # LLM verification for edge cases
        return self.llm_pii_check(output)
```

---

## CI/CD Integration Patterns

### GitHub Actions Integration

```yaml
# .github/workflows/llm-eval.yml
name: LLM Evaluation

on:
  pull_request:
    paths:
      - 'prompts/**'
      - 'src/llm/**'
  push:
    branches: [main]

jobs:
  evaluate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r requirements-eval.txt

      - name: Run evaluations
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          python eval/run_suite.py \
            --dataset eval/datasets/regression.jsonl \
            --output results.json

      - name: Check quality gates
        run: |
          python eval/check_gates.py results.json \
            --min-relevance 0.8 \
            --min-faithfulness 0.9 \
            --max-latency-p95 5000

      - name: Post results to PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const results = JSON.parse(fs.readFileSync('results.json'));
            const summary = formatResults(results);
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: summary
            });
```

### Quality Gates Implementation

```python
# eval/check_gates.py
import json
import sys
from dataclasses import dataclass

@dataclass
class QualityGate:
    metric: str
    threshold: float
    comparison: str  # "min", "max"

def check_gates(results_path: str, gates: list[QualityGate]) -> bool:
    with open(results_path) as f:
        results = json.load(f)

    failures = []

    for gate in gates:
        value = results.get(gate.metric, {}).get("mean")

        if value is None:
            failures.append(f"Metric {gate.metric} not found")
            continue

        if gate.comparison == "min" and value < gate.threshold:
            failures.append(
                f"{gate.metric}: {value:.3f} < {gate.threshold} (min)"
            )
        elif gate.comparison == "max" and value > gate.threshold:
            failures.append(
                f"{gate.metric}: {value:.3f} > {gate.threshold} (max)"
            )

    if failures:
        print("Quality gate failures:")
        for f in failures:
            print(f"  - {f}")
        return False

    print("All quality gates passed!")
    return True

if __name__ == "__main__":
    # Parse CLI args and run
    pass
```

### Promptfoo CI/CD Configuration

```yaml
# promptfoo.yaml
description: "Production prompt evaluation"

providers:
  - id: anthropic:claude-sonnet-4-20250514
    config:
      temperature: 0

prompts:
  - file://prompts/customer_service.txt

tests:
  - file://tests/regression_tests.yaml
  - file://tests/safety_tests.yaml

defaultTest:
  assert:
    - type: llm-rubric
      value: "Response is helpful and professional"
      threshold: 0.8

    - type: not-contains
      value: "I don't know"

# CI-specific settings
outputPath: results/eval_${new Date().toISOString()}.json

sharing:
  enabled: true
  teamId: ${PROMPTFOO_TEAM_ID}
```

### Caching for Efficiency

```python
class CachedEvaluator:
    """Cache evaluation results for unchanged inputs"""

    def __init__(self, cache_dir: str = ".eval_cache"):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(exist_ok=True)

    def get_cache_key(self, example: dict, metric_name: str) -> str:
        """Deterministic hash of inputs"""
        content = json.dumps(example, sort_keys=True) + metric_name
        return hashlib.sha256(content.encode()).hexdigest()

    def get_cached(self, key: str) -> Optional[float]:
        cache_file = self.cache_dir / f"{key}.json"
        if cache_file.exists():
            return json.loads(cache_file.read_text())["score"]
        return None

    def set_cached(self, key: str, score: float):
        cache_file = self.cache_dir / f"{key}.json"
        cache_file.write_text(json.dumps({
            "score": score,
            "timestamp": datetime.now().isoformat()
        }))

    def evaluate_with_cache(
        self,
        metric: BaseMetric,
        example: dict
    ) -> float:
        key = self.get_cache_key(example, metric.name)
        cached = self.get_cached(key)

        if cached is not None:
            return cached

        score = metric.compute(example)
        self.set_cached(key, score)
        return score
```

---

## Evaluation Orchestration Best Practices

### 1. Hierarchical Evaluation Strategy

```
Fast/Cheap (Every Commit)
├── Heuristic metrics (latency, tokens, errors)
├── Cached LLM evaluations
└── Subset sampling (10% of dataset)

Medium (Every PR)
├── Full LLM-as-judge evaluation
├── Safety metric suite
└── Regression test suite

Thorough (Pre-Release)
├── Agent-as-judge evaluation
├── Human evaluation sample
├── Red team testing
└── Full benchmark suite
```

### 2. Metric Aggregation

```python
class MetricAggregator:
    """Aggregate metrics into actionable scores"""

    def __init__(self, weights: dict = None):
        self.weights = weights or {}

    def compute_composite_score(self, results: dict) -> float:
        """Weighted average of normalized metrics"""
        total_weight = 0
        weighted_sum = 0

        for metric, data in results.items():
            weight = self.weights.get(metric, 1.0)
            score = data["mean"]

            weighted_sum += score * weight
            total_weight += weight

        return weighted_sum / total_weight if total_weight > 0 else 0

    def detect_regressions(
        self,
        current: dict,
        baseline: dict,
        threshold: float = 0.05
    ) -> list:
        """Find metrics that regressed beyond threshold"""
        regressions = []

        for metric in current:
            if metric not in baseline:
                continue

            current_score = current[metric]["mean"]
            baseline_score = baseline[metric]["mean"]
            delta = baseline_score - current_score

            if delta > threshold:
                regressions.append({
                    "metric": metric,
                    "current": current_score,
                    "baseline": baseline_score,
                    "delta": delta
                })

        return regressions
```

### 3. Async Evaluation Pipeline

```python
import asyncio
from typing import List

class AsyncEvaluationPipeline:
    """Parallel evaluation for throughput"""

    def __init__(self, max_concurrency: int = 10):
        self.semaphore = asyncio.Semaphore(max_concurrency)

    async def evaluate_example(
        self,
        example: dict,
        metrics: List[BaseMetric]
    ) -> dict:
        async with self.semaphore:
            results = {}
            for metric in metrics:
                # Run in thread pool for CPU-bound or sync operations
                score = await asyncio.to_thread(
                    metric.compute, example
                )
                results[metric.name] = score
            return results

    async def run(
        self,
        dataset: EvaluationDataset,
        metrics: List[BaseMetric]
    ) -> List[dict]:
        tasks = [
            self.evaluate_example(ex, metrics)
            for ex in dataset.examples
        ]
        return await asyncio.gather(*tasks)
```

### 4. Rate Limiting and Cost Control

```python
class EvaluationBudget:
    """Control evaluation costs"""

    def __init__(
        self,
        max_tokens: int = 100_000,
        max_cost: float = 10.0,
        max_duration_seconds: int = 3600
    ):
        self.max_tokens = max_tokens
        self.max_cost = max_cost
        self.max_duration = max_duration_seconds
        self.tokens_used = 0
        self.cost_incurred = 0
        self.start_time = None

    def start(self):
        self.start_time = time.time()

    def record_usage(self, tokens: int, cost: float):
        self.tokens_used += tokens
        self.cost_incurred += cost

    def check_budget(self) -> bool:
        if self.tokens_used >= self.max_tokens:
            raise BudgetExceeded(f"Token limit: {self.tokens_used}")

        if self.cost_incurred >= self.max_cost:
            raise BudgetExceeded(f"Cost limit: ${self.cost_incurred:.2f}")

        elapsed = time.time() - self.start_time
        if elapsed >= self.max_duration:
            raise BudgetExceeded(f"Time limit: {elapsed:.0f}s")

        return True
```

---

## Multi-Agent System Recommendations

### Evaluation Architecture for Multi-Agent

```
┌─────────────────────────────────────────────────────────┐
│                  Orchestrator Evaluation                 │
│  (Task routing, agent selection, overall coordination)   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ Agent A  │  │ Agent B  │  │ Agent C  │   ...        │
│  │ Eval     │  │ Eval     │  │ Eval     │              │
│  └──────────┘  └──────────┘  └──────────┘              │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                  Interaction Evaluation                  │
│     (Communication quality, handoff accuracy)            │
├─────────────────────────────────────────────────────────┤
│                  End-to-End Evaluation                   │
│        (Task completion, user satisfaction)              │
└─────────────────────────────────────────────────────────┘
```

### Multi-Agent Metrics

```python
class MultiAgentMetrics:
    """Metrics specific to multi-agent systems"""

    @staticmethod
    def coordination_efficiency(trace) -> float:
        """Measure agent coordination overhead"""
        useful_actions = count_useful_actions(trace)
        total_actions = len(trace.actions)
        return useful_actions / total_actions

    @staticmethod
    def handoff_accuracy(trace) -> float:
        """Measure quality of agent-to-agent handoffs"""
        handoffs = extract_handoffs(trace)
        successful = sum(1 for h in handoffs if h.was_successful)
        return successful / len(handoffs) if handoffs else 1.0

    @staticmethod
    def information_completeness(trace) -> float:
        """Check if required info is preserved across agents"""
        initial_context = trace.initial_context
        final_context = trace.final_context
        return context_overlap(initial_context, final_context)

    @staticmethod
    def parallel_efficiency(trace) -> float:
        """Measure parallelization effectiveness"""
        parallelizable = count_parallelizable(trace)
        actually_parallel = count_parallel_executions(trace)
        return actually_parallel / parallelizable if parallelizable else 1.0
```

### Simulation Testing

```python
class AgentSimulator:
    """Simulate multi-agent interactions for evaluation"""

    def __init__(self, agents: list, environment: SimulatedEnvironment):
        self.agents = agents
        self.environment = environment

    def run_scenario(self, scenario: dict) -> SimulationResult:
        """Run a complete scenario and collect traces"""
        self.environment.reset(scenario["initial_state"])

        traces = []
        for step in range(scenario["max_steps"]):
            for agent in self.agents:
                action = agent.act(self.environment.observe(agent.id))
                result = self.environment.step(action)
                traces.append({
                    "step": step,
                    "agent": agent.id,
                    "action": action,
                    "result": result
                })

                if self.environment.is_terminal:
                    break

        return SimulationResult(
            traces=traces,
            final_state=self.environment.state,
            success=self.environment.goal_achieved
        )
```

### Best Practices Summary

1. **Evaluate at multiple levels**: Individual agents, interactions, and end-to-end
2. **Use trace-based evaluation**: Capture full execution history
3. **Test failure modes**: Intentionally break individual agents
4. **Monitor coordination overhead**: Watch for inefficiencies
5. **Simulate edge cases**: Use synthetic scenarios
6. **Human-in-the-loop for complex failures**: Some failures need expert analysis

---

## Implementation Checklist

### Phase 1: Foundation
- [ ] Define core metric interface
- [ ] Implement dataset management
- [ ] Set up basic LLM-as-judge evaluator
- [ ] Create evaluation runner

### Phase 2: Metrics
- [ ] Implement universal metrics (latency, cost, errors)
- [ ] Add quality metrics (relevance, coherence)
- [ ] Add domain-specific metrics (RAG, safety, etc.)
- [ ] Validate metrics against human judgment

### Phase 3: CI/CD Integration
- [ ] GitHub Actions workflow
- [ ] Quality gate definitions
- [ ] Caching implementation
- [ ] PR comment automation

### Phase 4: Production
- [ ] Production trace sampling
- [ ] Real-time monitoring dashboards
- [ ] Alerting on regressions
- [ ] Continuous dataset updates

### Phase 5: Advanced
- [ ] Multi-agent evaluation
- [ ] Automated red teaming
- [ ] Human evaluation workflows
- [ ] A/B testing infrastructure

---

## Resources

### Code Templates
- GitHub: Search for "llm-evaluation-template"
- Promptfoo starter configs: https://github.com/promptfoo/promptfoo

### Further Reading
- [LLM Evaluation Best Practices](https://www.anthropic.com/research)
- [Building Production ML Systems](https://ml-ops.org/)
- [OpenTelemetry for LLMs](https://opentelemetry.io/)

---

*See also: [Open-Source Frameworks](./open-source-frameworks.md) | [Methodologies](./methodologies.md) | [Agent Benchmarks](./agent-benchmarks.md)*
