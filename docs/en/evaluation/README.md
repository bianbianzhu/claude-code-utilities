# LLM and Agent Evaluation Frameworks

This documentation provides a comprehensive guide to evaluating Large Language Models (LLMs) and AI agents in 2025. Whether you're selecting an off-the-shelf solution, integrating with cloud providers, or building your own evaluation system, this guide covers the essential tools, methodologies, and best practices.

## Why Evaluation Matters

As LLMs and AI agents become central to production applications, systematic evaluation is critical for:

- **Quality Assurance**: Ensuring outputs meet accuracy, relevance, and coherence standards
- **Safety and Compliance**: Detecting harmful outputs, bias, and security vulnerabilities
- **Cost Optimization**: Understanding token usage, latency, and resource consumption
- **Continuous Improvement**: Tracking performance over time and catching regressions
- **Stakeholder Confidence**: Providing transparent metrics for compliance and reporting

## The Evaluation Landscape at a Glance

| Category | Tools/Approaches | Best For |
|----------|-----------------|----------|
| **Open-Source Frameworks** | LangSmith, Ragas, DeepEval, Promptfoo, Arize Phoenix, TruLens, Giskard, OpenAI Evals, MLflow, W&B Weave | Full control, customization, cost-effective at scale |
| **Cloud Provider Solutions** | AWS Bedrock, Azure AI Foundry, Google Vertex AI | Native integrations, managed infrastructure |
| **Standard Benchmarks** | GAIA, AgentBench, WebArena, SWE-bench, ToolBench | Standardized comparison, capability measurement |
| **Custom Frameworks** | In-house solutions | Domain-specific requirements, unique metrics |

## Documentation Structure

### [Open-Source Frameworks](./open-source-frameworks.md)

Detailed coverage of 10 leading open-source evaluation frameworks:
- LangSmith, Ragas, DeepEval, Promptfoo, Giskard
- Arize Phoenix, TruLens, OpenAI Evals, MLflow, W&B Weave

Includes feature comparisons, pricing models, and agent evaluation capabilities.

### [Cloud Provider Solutions](./cloud-providers.md)

Evaluation capabilities from major cloud providers:
- AWS Bedrock Evaluations
- Azure AI Foundry Evaluation
- Google Vertex AI Gen AI Evaluation Service
- Anthropic's Evaluation Approaches

Comparison of native integrations and managed offerings.

### [Agent Benchmarks](./agent-benchmarks.md)

Standard benchmarks for measuring agent capabilities:
- GAIA, AgentBench, WebArena
- SWE-bench, ToolBench
- Emerging benchmarks (Terminal-Bench, Context-Bench, DPAI Arena)

What each measures and how to use them effectively.

### [Evaluation Methodologies](./methodologies.md)

Deep dive into evaluation techniques:
- LLM-as-Judge patterns (including bias types and mitigations)
- RAG evaluation (faithfulness, relevance, groundedness)
- Safety and alignment evaluation
- Multi-agent evaluation patterns

### [Building Your Own Framework](./building-your-own.md)

Practical guidance for custom evaluation systems:
- Common patterns across frameworks
- Essential metrics taxonomy
- CI/CD integration patterns
- Evaluation orchestration best practices
- Recommendations for multi-agent systems

## Quick Start Recommendations

### For RAG Applications
Start with **Ragas** for specialized RAG metrics (faithfulness, context precision, answer relevancy) or **TruLens** for the RAG Triad methodology.

### For Agent Evaluation
Use **DeepEval** for comprehensive agentic metrics or **Arize Phoenix** for observability-first evaluation with tracing.

### For Security Testing
Choose **Promptfoo** or **Giskard** for red teaming and vulnerability scanning.

### For Enterprise with Cloud Integration
- AWS users: **Bedrock Evaluations** with LLM-as-a-judge
- Azure users: **Azure AI Foundry** evaluation SDK
- GCP users: **Vertex AI Gen AI Evaluation Service**

### For CI/CD Integration
**Promptfoo** offers the most streamlined CI/CD experience with declarative YAML configs and built-in GitHub Actions support.

## Key Metrics to Track

| Metric Category | Examples | When to Use |
|----------------|----------|-------------|
| **Quality** | Accuracy, correctness, completeness | All applications |
| **Relevance** | Answer relevancy, context relevancy | QA, search, RAG |
| **Faithfulness** | Groundedness, hallucination detection | RAG, factual applications |
| **Coherence** | Fluency, logical flow, consistency | Long-form generation |
| **Safety** | Toxicity, bias, harmful content | All production applications |
| **Efficiency** | Latency, token count, cost | Production optimization |

## Evaluation Maturity Model

1. **Ad-hoc Testing**: Manual spot-checking of outputs
2. **Systematic Evaluation**: Defined test datasets and metrics
3. **Automated Evaluation**: LLM-as-judge and programmatic metrics
4. **Continuous Evaluation**: CI/CD integration with quality gates
5. **Production Monitoring**: Real-time evaluation of live traffic

## Contributing

This documentation is maintained as part of the claude-code-utilities project. For updates or corrections, please submit a pull request.

---

*Last updated: January 2026*
