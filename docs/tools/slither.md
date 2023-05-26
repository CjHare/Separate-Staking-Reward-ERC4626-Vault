# Slither - Solidity static analyzer

We use the Trail of Bits Solidity static analyzer [Slither](https://github.com/crytic/slither).

## Usage

Either setup and run in your local environment or in a Docker container.

### Local Environment

#### Install

With Python 3 in your environment, install using the Python package manager `pip3`:

```shell
pip3 install slither-analyzer
```

#### Run

When at the project root, to run using the project configuration:

```shell
slither . --config-file slither.json
```


## Excluded Detectors

### Solidity version too new

[incorrect-versions-of-solidity](https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity)
ensures an old version of Solidity (a previous minor version) is used, as the set of bugs and exploits are known.

When the release cycle is likely to span the release of a new minor of Solidity, using the latest version in development is acceptable (that version becomes a valid version by the time the audit has passed).

### Functions must be camel case

[conformance-to-solidity-naming-conventions](https://github.com/crytic/slither/wiki/Detector-Documentation#conformance-to-solidity-naming-conventions)
ensures functions aer in camel case.

The convention from Open Zeppelin upgradable contracts includes adding a CapWord for the contract to the init function.

e.g OwnableUpgradable

```solidity
    function __Ownable_init() internal initializer {
```

## Excluded Directories

Files and directories may be excluded when they are libraries, or are still under active development.

### Node Modules

“
Everything under `node_modules` is considered as a library (outside of the control of the project).
