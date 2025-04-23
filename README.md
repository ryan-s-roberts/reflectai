# ReflectAI

ReflectAI is a tool leveraging BoundaryML (BAML) to synthesize and analyze multimodal therapy session data. It aims to generate realistic, didactic scenarios and provide structured clinical analysis reports, including dialogue transcripts, identified themes, key moments, therapeutic observations, and session timelines.

## System Flow

The core process involves a sequence of BAML function calls orchestrated by the CLI to transform input context into a structured report:

1.  **Synthesize Dialogue & Base Events:** `SynthesizeTherapySession` generates the initial dialogue turns and basic non-visual modality events based on the input context.
2.  **Synthesize Visual Events:** `SynthesizeVisualEvents` takes the initial dialogue and context to generate plausible visual events (source: `VISUAL_ANALYSIS`) for patient turns. (Alternatively, `AnalyzeVisualInput` could be used here if image data were provided).
3.  **Merge Data (CLI):** The CLI merges the visual events into the dialogue structure.
4.  **Analyze Session:** `AnalyzeSessionMultimodal` processes the enriched dialogue and context to produce a structured `SessionAnalysis` object.
5.  **Generate Timeline Data:** `GenerateTimelineData` uses the enriched dialogue and the session analysis to create structured `TimelineData`.
6.  **Generate Report (CLI):** The CLI takes the `SessionAnalysis` and `TimelineData`, formats them (including rendering the timeline data to MermaidJS syntax), and assembles the final `report.md`.

```mermaid
flowchart TD
    A[Input: Context + Length] --> B(1. SynthesizeTherapySession);
    B --> C(2. SynthesizeVisualEvents);
    C --> D{Dialogue + Base Events + Visual Events};
    D --> E(3. AnalyzeSessionMultimodal);
    E --> F{SessionAnalysis};
    D --> G(4. GenerateTimelineData);
    F --> G;
    G --> H{TimelineData};
    subgraph Report Generation (CLI)
      F & H --> K[Assemble report.md];
    end
    K --> L[Output: report.md]
```

## Prerequisites

*   Node.js (v20 or later recommended)
*   npm
*   Docker (and Docker daemon running)
*   Exported API keys in your environment:
    *   `OPENAI_API_KEY`
    *   `ANTHROPIC_API_KEY`

## Installation & Setup

1.  **Clone the repository (if you haven't already).**
2.  **Install dependencies:**
    ```bash
    npm install
    ```
3.  **Export API Keys:** Make sure your Anthropic and OpenAI API keys are available as environment variables. Add these lines to your shell configuration file (like `.zshrc`, `.bashrc`, or `.bash_profile`) or export them manually in your current session:
    ```bash
    export OPENAI_API_KEY="your_openai_key_here"
    export ANTHROPIC_API_KEY="your_anthropic_key_here"
    ```
    *(Remember to restart your shell or source the configuration file after adding them)*

## Usage (Makefile)

The primary way to use ReflectAI is via the included `Makefile`.

1.  **Build the Docker Image:** (Required on first run or after code changes)
    ```bash
    make build
    ```
    *(This uses `docker build` and handles the multi-stage build process)*

2.  **Synthesize a Session & Generate Report:**
    This is the main command for generating a session report.
    ```bash
    # Ensure API keys are exported first!
    make synthesize CONTEXT="<Your clinical background context string>" LENGTH=<Approximate session length in minutes>
    ```
    *   `CONTEXT`: A string containing the background information for the desired session. **Must be quoted.**
    *   `LENGTH`: An integer representing the approximate desired session length in minutes.

    **Example:**
    ```bash
    make synthesize CONTEXT="Client is anxious about work presentations..." LENGTH=10
    ```
    This will:
    *   Build the image if necessary.
    *   Run the synthesis and analysis pipeline inside Docker.
    *   Save the resulting report to `./output/report.md` by default.

3.  **Customizing Output:**
    *   **Filename:** Change the output filename using the `REPORT_FILENAME` variable:
        ```bash
        make synthesize CONTEXT="..." LENGTH=5 REPORT_FILENAME=my_custom_report.md
        ```
        *(Output will be in `./output/my_custom_report.md`)*
    *   **Output Directory:** Change the host directory where output is saved using `HOST_OUTPUT_DIR`:
        ```bash
        make synthesize CONTEXT="..." LENGTH=8 HOST_OUTPUT_DIR=./session_reports
        ```
        *(Output will be in `./session_reports/report.md`)*

4.  **Other Commands:**
    *   `make clean`: Removes build artifacts (`dist/`, `src/baml_client/`) and the default output directory (`./output/`).
    *   `make help`: Displays usage information for the Makefile targets.
    *   `make run ARGS="..."`: Allows running arbitrary commands inside the container (more advanced usage).

## Examples

Below are some examples of generated reports using different clinical contexts. You can find the corresponding `make synthesize` invocations used to generate these within the project's chat history or by inspecting the report contents.

*   [Work Anxiety / Imposter Syndrome](./examples/work_anxiety_impostor.md)
*   [Student Depression / Withdrawal](./examples/student_depression_report.md)
*   [Anxiety Management Example](./examples/anxiety_management.md)

## License

This project is licensed under the ISC License - see the `package.json` file for details.
