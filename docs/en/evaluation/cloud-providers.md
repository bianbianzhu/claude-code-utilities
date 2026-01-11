# Cloud Provider LLM Evaluation Solutions

This document covers evaluation capabilities offered by major cloud providers and Anthropic, including their native integrations, managed infrastructure, and comparative analysis.

## Provider Comparison Matrix

| Provider | Service | LLM-as-Judge | RAG Eval | Agent Eval | Red Teaming | Pricing |
|----------|---------|--------------|----------|------------|-------------|---------|
| **AWS** | Bedrock Evaluations | GA (March 2025) | Yes | Preview | Limited | Pay per inference |
| **Azure** | AI Foundry | Yes | Yes | Yes | PyRIT integration | Pay per inference |
| **Google** | Gen AI Evaluation Service | Yes | Yes | Preview | Limited | Pay per inference |
| **Anthropic** | Model Cards + Benchmarks | Via API | Via partners | Research focus | Internal |Included in API |

---

## AWS Bedrock Evaluations

**Overview**: Amazon Bedrock provides comprehensive model evaluation capabilities including automatic, human, and LLM-as-a-judge evaluation methods.

### Key Features

#### LLM-as-a-Judge (Generally Available - March 2025)
- Evaluate all Bedrock models (serverless, marketplace, custom, imported)
- Human-like evaluation quality with up to 98% cost savings
- Evaluation time reduced from weeks to hours
- Compare results across evaluation jobs

#### Supported Model Types
- Serverless foundation models
- Bedrock Marketplace models (Converse API compatible)
- Custom and distilled models
- Imported models
- Model routers

### Evaluation Methods

| Method | Description | Best For |
|--------|-------------|----------|
| **Automatic (Programmatic)** | Curated/custom datasets with predefined metrics | Accuracy, robustness, toxicity |
| **Human Evaluation** | Built-in human labeler workflows | Subjective metrics (relevance, style, brand voice) |
| **LLM-as-a-Judge** | LLM evaluates responses against criteria | Scale human-like evaluation |

### Metrics Categories

| Category | Metrics |
|----------|---------|
| **Quality** | Correctness, completeness, faithfulness |
| **User Experience** | Helpfulness, coherence, relevance |
| **Instruction Compliance** | Following instructions, professional style |
| **Safety** | Harmfulness, stereotyping, refusal handling |

### RAG Evaluation Capabilities
- End-to-end RAG pipeline evaluation
- Evaluate Bedrock Knowledge Bases or custom RAG systems
- Citation coverage and precision metrics (new in 2025)
- Faithfulness and hallucination detection

### Agent Evaluation (Preview - AgentCore)

Amazon Bedrock AgentCore Evaluations provides:
- 13 built-in evaluators for correctness, helpfulness, and safety
- Real-time quality monitoring
- Automated risk assessment
- Custom evaluator creation with preferred prompts/models

### Regional Availability
US East (N. Virginia), US West (Oregon), Asia Pacific (Mumbai, Seoul, Sydney, Tokyo), Canada (Central), Europe (Frankfurt, Ireland, London, Paris, Zurich), South America (Sao Paulo)

### Pricing
- **No additional charges** for evaluation jobs
- Standard Bedrock pricing for model inference
- Evaluator models billed at normal on-demand/provisioned rates

### Integration Example

```python
import boto3

bedrock = boto3.client('bedrock')

# Create an evaluation job
response = bedrock.create_model_evaluation_job(
    jobName='my-evaluation',
    roleArn='arn:aws:iam::...',
    evaluationConfig={
        'automated': {
            'datasetMetricConfigs': [{
                'taskType': 'TEXT_GENERATION',
                'dataset': {'name': 'my-dataset'},
                'metricNames': ['Accuracy', 'Toxicity', 'Robustness']
            }]
        }
    },
    inferenceConfig={
        'models': [{'bedrockModel': {'modelIdentifier': 'anthropic.claude-3-sonnet-...'}}]
    }
)
```

### Pros
- Native AWS integration
- Comprehensive metric coverage
- Human evaluation workflows built-in
- AgentCore for agent-specific evaluation

### Cons
- AWS ecosystem lock-in
- Agent evaluation still in preview
- Less flexibility than open-source tools

---

## Azure AI Foundry Evaluation

**Overview**: Azure AI Foundry (formerly Azure AI Studio) provides enterprise-grade evaluation capabilities with strong .NET integration and adversarial testing.

### Key Features

#### Evaluation Types
- **AI Quality Metrics**: LLM-assisted quality and coherence evaluation
- **Synthetic Data Generation**: Auto-generate test datasets
- **Adversarial Testing**: Red teaming with PyRIT integration
- **Scheduled Evaluation**: Continuous quality and safety monitoring

#### Azure AI Evaluation SDK (Python)

Recent SDK features (2025):
- Reasoning model support for o1/o3 evaluators
- User-supplied tags for experiment tracking
- Enhanced GroundednessEvaluator with tool call support
- Agent-specific evaluators

### Evaluation Metrics

| Category | Metrics |
|----------|---------|
| **Quality** | Coherence, Fluency, Relevance, Similarity |
| **Groundedness** | GroundednessEvaluator (with agent support) |
| **Retrieval** | RetrievalEvaluator |
| **Safety** | Hate/unfairness, violence, sexual content |

### Agent Evaluators

Specialized evaluators for agentic workflows:

| Evaluator | Description |
|-----------|-------------|
| **tool_call_accuracy** | Validates correct tool invocation |
| **tool_selection** | Evaluates tool choice decisions |
| **tool_input_accuracy** | Checks tool parameter correctness |
| **tool_output_utilization** | Measures effective use of tool results |

### Red Teaming and Adversarial Testing

#### PyRIT Integration
- AI red teaming agent for complex adversarial attacks
- Microsoft's Python Risk Identification Tool
- Multi-turn attack simulations

#### Simulator Features
- Topic-related query generation
- Adversarial/attack-like query generation
- Edge case testing

### .NET Evaluation Libraries

**Microsoft.Extensions.AI.Evaluation**:
- Quality metrics (relevance, truthfulness, coherence, completeness)
- Safety metrics (hate/unfairness, violence, sexual content)
- Built-in response caching for CI/CD efficiency
- Incremental evaluations with cache reuse

```csharp
using Microsoft.Extensions.AI.Evaluation;

var evaluator = new RelevanceEvaluator();
var result = await evaluator.EvaluateAsync(
    question: "What is the capital of France?",
    response: "The capital of France is Paris.",
    context: "France is a country in Western Europe..."
);
```

### Scheduled Evaluation (Production)
- Continuous drift detection
- Automated red teaming at intervals
- Quality gate enforcement

### Pricing
- **No separate evaluation fees**
- Standard Azure OpenAI/AI Services pricing
- Additional costs for evaluator model inference

### Integration Example (Python SDK)

```python
from azure.ai.evaluation import evaluate, GroundednessEvaluator

groundedness = GroundednessEvaluator(model_config)

result = evaluate(
    data="test_data.jsonl",
    evaluators={
        "groundedness": groundedness
    },
    evaluator_config={
        "groundedness": {
            "is_reasoning_model": True  # For o1/o3 models
        }
    }
)
```

### Pros
- Strong enterprise security and compliance
- Excellent .NET support
- Built-in red teaming with PyRIT
- Agent-specific evaluators

### Cons
- Azure ecosystem dependency
- Complex pricing across services
- Some features require Azure OpenAI

---

## Google Vertex AI Gen AI Evaluation Service

**Overview**: Google's Gen AI Evaluation Service provides enterprise-grade tools with unique adaptive rubrics and multimodal evaluation capabilities.

### Key Features

#### Adaptive Rubrics (Recommended Approach)
- Tailored pass/fail tests for each individual prompt
- Similar to unit tests in software development
- Automatically generates unique rubrics per prompt
- Two-step process: rubric generation + validation

#### Evaluation Process
1. **Rubric Generation**: Service analyzes prompt and generates specific tests
2. **Rubric Validation**: Response assessed against each rubric with Pass/Fail verdict and rationale

### Metrics Supported

| Type | Metrics |
|------|---------|
| **Computational** | ROUGE, BLEU, exact match |
| **Model-Based** | PointwiseMetric, PairwiseMetric (customizable) |
| **Translation** | MetricX, COMET, BLEU |
| **Multimodal** | Gecko (image/video evaluation) |

### Interfaces

| Interface | Description |
|-----------|-------------|
| **Google Cloud Console** | Guided web UI with dataset management and visualizations |
| **Python SDK** | Programmatic evaluation in Colab/Jupyter |
| **GenAI Client** | Vertex AI SDK integration |

### Agent Evaluation (Preview - 2025)
- Evaluate agents using Gen AI Client
- Integration with Vertex AI Agent Builder
- Custom evaluation criteria for agent workflows

### Multimodal Evaluation with Gecko
- Rubric-based image and video evaluation
- Customizable assessment criteria
- Transparent scoring rationale
- Support for generative image/video models

### Recent Updates (2025)
- Agent evaluation (Preview)
- Translation model evaluation (MetricX, COMET)
- Enhanced GenAI Client support

### Use Cases
- **Model Selection**: Compare models for specific use cases
- **Configuration Optimization**: Tune model parameters
- **Prompt Engineering**: Iterate on prompts
- **Fine-tuning Validation**: Verify improvements

### Pricing
- **Standard Vertex AI pricing** for model inference
- No additional evaluation service fees
- Judge model calls billed separately

### Integration Example

```python
from vertexai.preview.evaluation import EvalTask

eval_task = EvalTask(
    dataset="gs://my-bucket/eval_data.jsonl",
    metrics=["groundedness", "fulfillment", "summarization_quality"],
    experiment="my-evaluation-experiment"
)

result = eval_task.evaluate(
    model="gemini-2.0-pro",
    prompt_template="{context}\n\nQuestion: {question}"
)
```

### Pros
- Unique adaptive rubrics approach
- Multimodal evaluation (Gecko)
- Strong Google Cloud integration
- Translation-specific metrics

### Cons
- GCP ecosystem lock-in
- Agent evaluation still in preview
- Less mature than AWS/Azure offerings

---

## Anthropic's Evaluation Approaches

**Overview**: Anthropic takes a research-focused approach to evaluation, publishing detailed model cards, system cards, and contributing to industry benchmarks.

### Evaluation Philosophy

Anthropic emphasizes:
- **Transparency**: Detailed model cards and system cards
- **Safety**: CBRN evaluations, alignment testing
- **Robustness**: Prompt injection resistance
- **Agentic Safety**: Behavior in autonomous scenarios

### Key Benchmarks Used (2025)

| Benchmark | Focus Area |
|-----------|------------|
| **SWE-bench Verified** | Software engineering capability |
| **Terminal-bench** | Command-line agent tasks |
| **GPQA-Diamond** | Graduate-level science knowledge |
| **TAU-bench** | Tool-augmented reasoning |
| **MMMLU** | Massive multitask language understanding |
| **MMMU** | Multimodal understanding |
| **AIME 2025** | Advanced mathematics |

### Safety Evaluation Framework

#### ASL (AI Safety Level) Thresholds
- **ASL-3**: Significant CBRN uplift capability
- **ASL-4**: State-program level capability uplift

#### Safety Dimensions
- CBRN (Chemical, Biological, Radiological, Nuclear) evaluations
- Mechanistic interpretability testing
- Prompt injection robustness
- Agentic behavior analysis

### Recent Results (Claude Opus 4.5 - November 2025)
- 80.9% on SWE-bench Verified (state-of-the-art)
- Industry-leading prompt injection robustness
- ~10% less concerning behavior than competitors on agentic safety
- Approached but did not cross ASL-4 threshold

### Model Cards and Transparency

Anthropic publishes:
- **Model Cards**: Capability descriptions and limitations
- **System Cards**: Safety evaluations and testing methodologies
- **Transparency Hub**: Ongoing capability assessments

### Integration for Evaluation

While Anthropic doesn't offer a dedicated evaluation platform, you can:

1. **Use Claude as an evaluator** via the API
2. **Integrate with open-source frameworks** (DeepEval, Ragas, etc.)
3. **Reference official benchmarks** for comparison

```python
import anthropic

client = anthropic.Anthropic()

# Use Claude as an LLM-as-judge evaluator
evaluation_prompt = """
Evaluate the following response for accuracy and helpfulness.

Question: {question}
Response: {response}
Reference: {reference}

Score from 1-5 and explain your reasoning.
"""

result = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=500,
    messages=[{"role": "user", "content": evaluation_prompt.format(...)}]
)
```

### Pros
- Exceptional transparency and documentation
- Leading safety evaluation practices
- Strong academic and research foundation
- Model robustness (prompt injection resistance)

### Cons
- No dedicated evaluation platform
- Requires third-party tools for structured evaluation
- Benchmarks focused on safety over general quality

---

## Cloud Provider Comparison

### Feature Comparison

| Feature | AWS Bedrock | Azure AI Foundry | Google Vertex AI | Anthropic |
|---------|-------------|------------------|------------------|-----------|
| **LLM-as-Judge** | GA | Yes | Yes | Via API |
| **Human Evaluation** | Built-in workflows | Supported | Via console | Manual |
| **RAG Evaluation** | Yes + citations | Yes | Yes | Via partners |
| **Agent Evaluation** | Preview (AgentCore) | Yes | Preview | Research |
| **Red Teaming** | Limited | PyRIT integration | Limited | Internal only |
| **Multimodal Eval** | Limited | Limited | Gecko | Limited |
| **Self-hosted Option** | No | No | No | N/A |

### Choosing a Provider

#### Choose AWS Bedrock if:
- Already invested in AWS ecosystem
- Need multi-model comparison (Anthropic, Meta, etc.)
- Want managed human evaluation workflows
- Using Bedrock Knowledge Bases for RAG

#### Choose Azure AI Foundry if:
- Enterprise with Microsoft/Azure commitment
- Need .NET/C# integration
- Require advanced red teaming (PyRIT)
- Building agents with Azure OpenAI

#### Choose Google Vertex AI if:
- Google Cloud infrastructure
- Need multimodal evaluation (images/video)
- Prefer adaptive rubrics methodology
- Using Gemini models

#### Choose Anthropic (with partners) if:
- Primary Claude user
- Safety-critical applications
- Need transparency and documentation
- Comfortable with third-party eval tools

### Migration Considerations

If you need to avoid vendor lock-in:

1. **Use OpenTelemetry** for tracing (supported by all)
2. **Adopt open-source frameworks** (Ragas, DeepEval) alongside cloud tools
3. **Standardize metrics** that work across providers
4. **Export evaluation datasets** in portable formats (JSONL)

---

*See also: [Open-Source Frameworks](./open-source-frameworks.md) | [Agent Benchmarks](./agent-benchmarks.md) | [Methodologies](./methodologies.md)*
