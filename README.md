# StormForge Labs

Cloud security lab scenarios for [StormForge](https://github.com/opteron-x86/stormforge).

## Installation

```bash
# With StormForge CLI
sf fetch

# Or fetch specific provider
sf fetch aws
```

## Labs

### AWS

| Lab | Description | Techniques |
|-----|-------------|------------|
| *Coming soon* | | |

### Azure

| Lab | Description | Techniques |
|-----|-------------|------------|
| *Coming soon* | | |

### GCP

| Lab | Description | Techniques |
|-----|-------------|------------|
| *Coming soon* | | |

## Lab Structure

Each lab follows this structure:

```
aws/lab-name/
├── README.md           # Lab description, objectives, walkthrough
├── main.tf             # Primary terraform configuration
├── variables.tf        # Input variables
├── outputs.tf          # Output values
└── versions.tf         # Provider requirements
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding new labs.

## License

Apache 2.0 - See [LICENSE](LICENSE)
