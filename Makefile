# Variables
IMAGE_NAME := reflectai-cli
IMAGE_TAG := latest
DOCKER_PLATFORM := linux/amd64 # Specify target platform(s)
HOST_OUTPUT_DIR := ./output    # Default output directory on the host
REPORT_FILENAME := report.md   # Default report filename

# Phony targets (targets that don't represent files)
.PHONY: build run synthesize clean help all

# Default target
all: build

# Build the Docker image
# Using DOCKER_BUILDKIT=0 as a workaround for potential credential helper issues
build:
	@echo "Building Docker image $(IMAGE_NAME):$(IMAGE_TAG) for platform $(DOCKER_PLATFORM) (BuildKit disabled)..."
	DOCKER_BUILDKIT=0 docker build --platform $(DOCKER_PLATFORM) -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "Build complete."

# Internal run target (called by synthesize)
# Sets up environment variables and volume mounts
run:
	@# This target expects ARGS to be set by the caller (e.g., synthesize target)
	@echo "Ensuring host output directory exists: $(HOST_OUTPUT_DIR)"
	mkdir -p $(HOST_OUTPUT_DIR)
	@echo "(Output from /app/output in container will appear in host's $(HOST_OUTPUT_DIR))"
	docker run --rm -it \
		-e OPENAI_API_KEY \
		-e ANTHROPIC_API_KEY \
		-v "$(shell pwd)/$(HOST_OUTPUT_DIR)":/app/output \
		$(IMAGE_NAME):$(IMAGE_TAG) $(ARGS)

# Target to synthesize a session and generate a report
# Requires CONTEXT and LENGTH variables to be passed.
# Example: make synthesize CONTEXT="Client context..." LENGTH=10
synthesize: build
	@# Check if CONTEXT and LENGTH variables are set
	@if [ -z "$(CONTEXT)" ]; then echo "Error: CONTEXT variable is not set."; exit 1; fi
	@if [ -z "$(LENGTH)" ]; then echo "Error: LENGTH variable is not set."; exit 1; fi
	@echo "Synthesizing session (Context: '$(CONTEXT)', Length: $(LENGTH) mins)..."
	$(MAKE) run ARGS="synthesize -c \"$(CONTEXT)\" -l $(LENGTH) --output /app/output/$(REPORT_FILENAME)"
	@echo "Synthesis complete. Report saved to $(HOST_OUTPUT_DIR)/$(REPORT_FILENAME)"

# Clean build artifacts (optional)
clean:
	@echo "Cleaning build artifacts..."
	rm -rf ./dist
	rm -rf ./src/baml_client
	rm -rf $(HOST_OUTPUT_DIR) # Also remove default output dir
	@echo "Clean complete."

# Help target (optional)
help:
	@echo "Makefile for $(IMAGE_NAME)"
	@echo ""
	@echo "Usage:"
	@echo "  make build                      Build the Docker image"
	@echo "  make synthesize CONTEXT=\"...\" LENGTH=<mins>  Synthesize a session and save report."
	@echo "                                  Requires CONTEXT (string) and LENGTH (number) variables."
	@echo "                                  Report saved to $(HOST_OUTPUT_DIR)/$(REPORT_FILENAME)"
	@echo "  make run ARGS=\"...\"              Run arbitrary CLI commands in Docker (Internal use or advanced)."
	@echo "                                  API keys (OPENAI_API_KEY, ANTHROPIC_API_KEY) are passed from host env."
	@echo "                                  Host directory '$(HOST_OUTPUT_DIR)' is mounted to '/app/output' in container."
	@echo "  make clean                      Remove local build artifacts (dist/, src/baml_client/, $(HOST_OUTPUT_DIR)/)"
	@echo "  make help                       Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  HOST_OUTPUT_DIR (default: $(HOST_OUTPUT_DIR))  Local directory to mount for output."
	@echo "  REPORT_FILENAME (default: $(REPORT_FILENAME)) Filename for synthesize report."
	@echo "" 