# Open-Source LLM Evaluation Frameworks

This document provides detailed coverage of the leading open-source frameworks for evaluating LLMs and AI agents, including their features, metrics, pricing, and best use cases.

## Framework Comparison Matrix

| Framework | Focus Area | Agent Support | CI/CD Integration | Pricing Model |
|-----------|-----------|---------------|-------------------|---------------|
| **LangSmith** | Full lifecycle | Strong | Native | Freemium + Usage |
| **Ragas** | RAG evaluation | Limited | Via Python | Open Source |
| **DeepEval** | Comprehensive testing | Strong | pytest-native | Open Source + Cloud |
| **Promptfoo** | Testing & Security | Moderate | Native YAML | Open Source |
| **Giskard** | Security & Quality | Moderate | MLflow integration | Open Source + Enterprise |
| **Arize Phoenix** | Observability | Strong | OpenTelemetry | Open Source + Cloud |
| **TruLens** | RAG Triad | Moderate | Via Python | Open Source |
| **OpenAI Evals** | Benchmark registry | Limited | Via API | Open Source |
| **MLflow** | MLOps integration | Strong | Native | Open Source |
| **W&B Weave** | Experiment tracking | Strong | Native | Freemium |

---

## LangSmith

**Overview**: LangSmith is a comprehensive platform for debugging, testing, evaluating, and monitoring LLM applications, built by LangChain.

### Key Features
- **Tracing**: Full visibility into LLM call chains with automatic instrumentation
- **Datasets**: Create and manage evaluation datasets with versioning
- **Human Evaluation**: Built-in workflows for human labeling and feedback
- **Cost Tracking**: Token usage and cost monitoring with dashboards
- **Auto-evaluation**: Built-in evaluators for similarity, factuality, and more

### Metrics Supported
- Similarity comparison
- Factuality checking
- Custom evaluator functions
- Human feedback integration
- Latency and token metrics

### Agent Evaluation Capabilities
- Full trace visualization for agent workflows
- Step-by-step debugging of agent decisions
- Tool call tracking and analysis
- Multi-step evaluation across agent trajectories

### Pros
- Tight integration with LangChain ecosystem
- Excellent debugging and tracing UI
- Comprehensive human-in-the-loop workflows
- Strong community and documentation

### Cons
- Costs can escalate with high trace volume
- Best experience requires LangChain adoption
- Self-hosting requires enterprise plan

### Pricing Model
| Plan | Cost | Included |
|------|------|----------|
| Developer (Free) | $0 | 5k base traces/month, 1 seat |
| Plus | $39/user/month | 10k base traces/month, up to 10 seats |
| Enterprise | Custom | Self-hosting, advanced security |

**Trace Pricing**:
- Base traces (14-day retention): $0.50/1k traces
- Extended traces (400-day retention): $5.00/1k traces

---

## Ragas

**Overview**: Ragas (Retrieval Augmented Generation Assessment) is a framework specifically designed for reference-free evaluation of RAG pipelines.

### Key Features
- **Reference-free Evaluation**: No ground truth annotations required
- **Comprehensive RAG Metrics**: Specialized metrics for retrieval and generation
- **Automatic Test Generation**: Generate test datasets from knowledge bases
- **Framework Integrations**: Works with LangChain and major observability tools

### Metrics Supported

#### Core RAG Metrics
| Metric | Description |
|--------|-------------|
| **Faithfulness** | Factual accuracy of response vs. retrieved context |
| **Answer Relevancy** | How relevant the response is to the query |
| **Context Precision** | Precision of retrieved documents |
| **Context Recall** | Coverage of relevant information in retrieval |

#### Extended Metrics (November 2025)
- Context Entities Recall
- Noise Sensitivity
- Response Groundedness
- Topic Adherence
- Factual Correctness
- Semantic Similarity
- BLEU, ROUGE, CHRF scores
- SQL Query Equivalence
- Tool Call Accuracy/F1
- Agent Goal Accuracy

### Agent Evaluation Capabilities
- Tool Call Accuracy metric
- Agent Goal Accuracy for task completion
- Limited compared to dedicated agent frameworks

### Pros
- Best-in-class RAG evaluation metrics
- No ground truth required for many metrics
- Strong academic foundation (peer-reviewed paper)
- Lightweight and easy to integrate

### Cons
- Primarily focused on RAG (less general-purpose)
- Limited built-in UI/dashboard
- Agent evaluation is secondary focus

### Pricing Model
- **Fully Open Source** (Apache 2.0)
- No commercial tiers

---

## DeepEval

**Overview**: DeepEval is a pytest-like framework for unit testing LLM outputs, offering 50+ metrics for comprehensive evaluation.

### Key Features
- **pytest Integration**: Familiar testing syntax for developers
- **50+ Built-in Metrics**: Extensive metric library out of the box
- **LLM-as-Judge**: G-Eval for custom evaluation criteria
- **Agentic Metrics**: Specialized metrics for AI agents
- **DeepTeam**: Companion red teaming framework

### Metrics Supported

#### RAG Metrics
- ContextualPrecisionMetric
- ContextualRecallMetric
- FaithfulnessMetric
- AnswerRelevancyMetric

#### Agentic Metrics
| Metric | Description |
|--------|-------------|
| **PlanQualityMetric** | Evaluates agent plan logic and completeness |
| **PlanAdherenceMetric** | Checks if agent follows its own plan |
| **ToolCorrectnessMetric** | Validates tool selection and invocation |

#### General Metrics
- G-Eval (custom criteria)
- Coherence, Fluency
- Bias, Toxicity
- Summarization quality

### Agent Evaluation Capabilities
- Full execution trace analysis
- Multi-step reasoning evaluation
- Tool call correctness validation
- Plan quality assessment

### Pros
- Most comprehensive metric library
- Familiar pytest-style testing
- Strong agentic evaluation support
- Active development and community

### Cons
- Scores 0-1 may need calibration
- LLM-as-judge costs for complex metrics
- Learning curve for custom metrics

### Pricing Model
- **Open Source**: Core framework free
- **Confident AI Cloud**: Optional SaaS for dashboards and collaboration

---

## Promptfoo

**Overview**: Promptfoo is a developer-friendly CLI and library for systematic prompt testing, evaluation, and security scanning.

### Key Features
- **Declarative YAML Configs**: Version-controlled test definitions
- **Red Teaming**: Built-in security vulnerability scanning
- **Provider Agnostic**: Works with 50+ LLM providers
- **CI/CD Native**: First-class GitHub Actions and pipeline support
- **Fast Iteration**: Live reloads and caching

### Metrics Supported
- llm-rubric (custom natural language criteria)
- G-Eval (chain-of-thought scoring)
- ROUGE-N, BLEU (lexical similarity)
- Custom assertion types
- Security vulnerability scores

### Security Testing (Unique Strength)
- Prompt injection detection
- Jailbreak vulnerability scanning
- PII leakage testing
- 50+ vulnerability types covered
- OWASP and NIST compliance reporting

### Agent Evaluation Capabilities
- LangGraph evaluation support
- Tool call validation
- Multi-step workflow testing
- Limited compared to DeepEval's agentic metrics

### Pros
- Best-in-class CI/CD integration
- Unique security testing focus
- Simple declarative configuration
- Excellent developer experience
- 200K+ user community

### Cons
- Less sophisticated agentic metrics
- UI less polished than cloud offerings
- Security focus may be overkill for simple use cases

### Pricing Model
- **Fully Open Source**
- Enterprise support available

---

## Giskard

**Overview**: Giskard is an open-source testing framework for ML models with a strong focus on LLM security, bias detection, and quality assurance.

### Key Features
- **Automated Vulnerability Detection**: Security and business failure identification
- **RAGET (RAG Evaluation Toolkit)**: Automated test generation for RAG
- **LLM Scan**: Heuristic and LLM-assisted vulnerability detection
- **Continuous Testing**: Pre and post-deployment evaluation
- **Phare Benchmark**: Independent LLM safety benchmark (with Google DeepMind)

### Metrics Supported
- Hallucination detection
- Stereotyping and bias metrics
- Prompt injection vulnerability
- Factual accuracy
- Domain-specific security failures

### RAGET Features
| Component | Description |
|-----------|-------------|
| **Question Generation** | Auto-generate test questions from knowledge base |
| **Reference Answers** | Generate ground truth answers |
| **Reference Context** | Track expected retrieval context |
| **Component Scoring** | Separate Generator and Retriever scores |

### Agent Evaluation Capabilities
- Black-box API testing
- Continuous vulnerability monitoring
- Limited native agent-specific metrics

### Pros
- Strong security and bias focus
- MLflow integration
- Enterprise-ready features
- Academic partnerships (DeepMind)
- GDPR/SOC2/HIPAA compliance options

### Cons
- Less comprehensive general metrics
- Steeper learning curve
- Primary focus on vulnerabilities over quality

### Pricing Model
- **Open Source**: Core framework free
- **Enterprise**: Data residency, RBAC, audit trails, SSO

---

## Arize Phoenix

**Overview**: Phoenix is an open-source AI observability platform for experimentation, evaluation, and troubleshooting, built on OpenTelemetry standards.

### Key Features
- **OpenTelemetry Native**: Industry-standard tracing
- **Trace Visualization**: Span-level debugging and analysis
- **LLM Evaluators**: Built-in and custom evaluation
- **Prompt Playground**: Interactive prompt testing
- **Self-Hostable**: No feature gates or restrictions

### Metrics Supported
- Response evaluation (quality, relevance)
- Retrieval evaluation (precision, recall)
- Latency and token metrics
- Custom LLM-based evaluators
- Human annotation workflows

### Framework Support
- LlamaIndex, LangChain, Haystack, DSPy, smolagents
- OpenAI, Anthropic, Bedrock, VertexAI, MistralAI
- Any OpenTelemetry-compatible system

### Agent Evaluation Capabilities
- Full trace visibility for agent workflows
- Span-level analysis for debugging
- Tool call tracking
- Multi-step workflow evaluation

### Pros
- OpenTelemetry standard (vendor-agnostic)
- Excellent observability UI
- Self-hostable with no restrictions
- Strong framework integrations
- 7,800+ GitHub stars

### Cons
- Elastic License 2.0 (not pure OSS)
- Less specialized metrics than Ragas/DeepEval
- Observability-first (evaluation secondary)

### Pricing Model
- **Open Source**: Self-hosted, no limits
- **Arize Cloud**: Managed hosting at app.phoenix.arize.com

---

## TruLens

**Overview**: TruLens is an evaluation framework focused on the "RAG Triad" methodology, originally created by TruEra (now Snowflake).

### Key Features
- **RAG Triad**: Three-pillar evaluation methodology
- **Feedback Functions**: Programmatic evaluation at scale
- **Provider Agnostic**: Multiple LLM provider integrations
- **OpenTelemetry Support**: Modern observability standards

### RAG Triad Metrics
| Metric | Relationship Measured |
|--------|----------------------|
| **Response Relevance** | Answer to Query |
| **Context Relevance** | Retrieved Context to Query |
| **Groundedness** | Answer to Retrieved Context |

### Provider Integrations
- trulens-providers-openai
- trulens-providers-huggingface
- trulens-providers-litellm
- trulens-providers-langchain

### Agent Evaluation Capabilities
- Span-based evaluation (2025 update)
- OpenTelemetry tracing for agents
- Limited dedicated agentic metrics

### Pros
- Clear, principled methodology (RAG Triad)
- Academic foundation
- Snowflake backing and resources
- Modular provider architecture

### Cons
- Narrower focus than comprehensive tools
- Less active development post-acquisition
- Documentation can be sparse

### Pricing Model
- **Fully Open Source** (MIT License)

---

## OpenAI Evals

**Overview**: OpenAI Evals is an open-source framework for evaluating LLMs with a community-driven benchmark registry.

### Key Features
- **Benchmark Registry**: Pre-built tests for common tasks
- **Custom Evals**: Define domain-specific evaluations
- **Model-Graded Evals**: LLM-as-judge support
- **Dashboard Access**: Web UI for configuration
- **HealthBench**: Healthcare-specific benchmark (2025)

### Evaluation Types
| Type | Description |
|------|-------------|
| **Basic (Ground Truth)** | Compare to known correct answers |
| **Model-Graded** | Use LLM to judge quality |
| **Custom** | Define your own evaluation logic |

### Metrics Supported
- Question answering accuracy
- Logic puzzle solving
- Code generation quality
- Content compliance
- Domain-specific benchmarks

### Agent Evaluation Capabilities
- Limited native agent support
- Focus on single-turn evaluation
- Multi-step workflows require custom setup

### Pros
- Official OpenAI framework
- Large community benchmark registry
- No coding required for basic evals
- Web dashboard access

### Cons
- OpenAI-centric design
- Less comprehensive than alternatives
- Limited agent evaluation
- Basic UI compared to modern tools

### Pricing Model
- **Open Source**: Framework free
- **API Costs**: Standard OpenAI pricing for model calls

---

## MLflow

**Overview**: MLflow's LLM evaluation module integrates evaluation into the broader MLOps lifecycle with comprehensive tracking and experiment management.

### Key Features
- **MLOps Integration**: Part of complete ML lifecycle platform
- **Heuristic Metrics**: answer_similarity, exact_match, latency
- **LLM-as-Judge**: Built-in and custom judge scorers
- **Experiment Tracking**: Full versioning and comparison
- **OpenTelemetry Metrics**: Span-level observability (2025)

### Recent Features (2025)
| Version | Feature |
|---------|---------|
| 3.8.0 | DeepEval/RAGAS integration (20+ metrics) |
| 3.8.0 | Conversational Safety Scorer |
| 3.8.0 | Tool Call Efficiency Scorer |
| 3.4.0 | Custom make_judge API |
| 3.4.0 | Dataset versioning in experiments |

### Metrics Supported
- Heuristic: answer_similarity, exact_match, latency, token_count
- LLM-as-Judge: Coherence, relevance, harmfulness
- Integrated: DeepEval and RAGAS metrics
- Custom: make_judge API for domain-specific

### Agent Evaluation Capabilities
- Conversational Tool Call Efficiency Scorer
- Span-level tracing and metrics
- Multi-turn conversation evaluation
- Safety evaluation for conversations

### Pros
- Full MLOps integration
- Strong experiment tracking
- Enterprise-ready (Databricks backing)
- Excellent versioning and reproducibility

### Cons
- Heavier setup than lightweight tools
- Less specialized for LLMs than dedicated tools
- UI focused on ML experiments, not LLM-specific

### Pricing Model
- **Open Source**: Core framework free
- **Managed MLflow**: Via Databricks

---

## Weights & Biases Weave

**Overview**: Weave is W&B's toolkit for developing GenAI applications, providing tracing, evaluation, and production monitoring.

### Key Features
- **Auto-Patching**: Automatic LLM library instrumentation
- **Evaluation Objects**: Structured dataset + scorer workflows
- **Version Control**: Automatic code, dataset, and scorer versioning
- **Online Evals**: Score live production traces
- **OpenTelemetry Support**: Send traces from any OTEL backend

### Metrics Supported
- Custom scoring functions
- Programmatic checks
- LLM-based judges
- Production monitoring metrics

### Integration with Cloud (2025)
- Amazon Bedrock integration for enterprise agentic AI
- Full lifecycle support from experimentation to production

### Agent Evaluation Capabilities
- Full trace visualization
- Multi-step workflow evaluation
- Tool call tracking
- Production monitoring for agents

### Pros
- Excellent experiment tracking heritage
- Strong versioning and reproducibility
- Production monitoring included
- OpenTelemetry support for flexibility

### Cons
- Requires W&B ecosystem buy-in
- Less specialized metrics than dedicated tools
- Pricing can accumulate for heavy usage

### Pricing Model
| Plan | Cost |
|------|------|
| Free | Limited usage |
| Teams | $50/user/month |
| Enterprise | Custom |

---

## Choosing the Right Framework

### Decision Tree

```
Need RAG-specific evaluation?
├── Yes → Ragas or TruLens
└── No
    ├── Need security/red teaming? → Promptfoo or Giskard
    ├── Need agent evaluation? → DeepEval or Arize Phoenix
    ├── Need MLOps integration? → MLflow or W&B Weave
    ├── Need full lifecycle observability? → LangSmith or Arize Phoenix
    └── Building custom benchmarks? → OpenAI Evals
```

### Use Case Recommendations

| Use Case | Primary | Alternative |
|----------|---------|-------------|
| RAG Quality | Ragas | TruLens |
| Agent Testing | DeepEval | Arize Phoenix |
| Security Scanning | Promptfoo | Giskard |
| CI/CD Integration | Promptfoo | DeepEval |
| Full Observability | Arize Phoenix | LangSmith |
| Enterprise MLOps | MLflow | W&B Weave |
| OpenAI Ecosystem | OpenAI Evals | LangSmith |
| LangChain Apps | LangSmith | Arize Phoenix |

---

*See also: [Cloud Provider Solutions](./cloud-providers.md) | [Agent Benchmarks](./agent-benchmarks.md) | [Building Your Own](./building-your-own.md)*
