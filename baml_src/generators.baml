// This helps use auto generate libraries you can use in the language of
// your choice. You can have multiple generators if you use multiple languages.
// Just ensure that the output_dir is different for each generator.
generator target {
    // Valid values: "python/pydantic", "typescript", "ruby/sorbet", "rest/openapi"
    output_type "typescript"

    // Where the generated code will be saved (relative to baml_src/)
    // The generator seems to create a 'baml_client' dir WITHIN this path.
    output_dir "../src" // Output under src directory

    // The version of the BAML package you have installed (e.g. same version as your baml-py or @boundaryml/baml).
    // The BAML VSCode extension version should also match this version.
    version "0.84.4"

    // 'baml-cli generate' will run this after generating openapi.yaml, to generate your OpenAPI client
    // This command will be run from within $output_dir/baml_client
    // on_generate "npx @openapitools/openapi-generator-cli generate -i openapi.yaml -g rust -o . --additional-properties packageName=baml-client,avoidBoxedModels=true"
}
