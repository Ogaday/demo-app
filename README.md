# Single Sourcing Poetry Apps on Docker

Demo of a simple, containerised Python app packaged with Poetry, versioned by
git tags.

[`Poetry`](https://python-poetry.org/) is a fantastic tool for packaging python
libraries and applications. The
[`poetry-dynamic-versioning`](https://github.com/mtkennerly/poetry-dynamic-versioning)
plugin thinly wraps the `poetry` build system and looks up the package version
from your source control (such as git tags), and injects them into the build
info (ie. package metadata) and optionally into the distributed source code
itself, for instance overwriting the `__version__` variable in `__init__.py`.

The advantage of this is that your package version has a single source, tied to
version control, and there's no need for multi-step tag increments, and not
chance of version strings falling out of sync.

Unfortunately, the docker build process can can cause some complications.
Typically, the git repo data is no available during the build process. This
project demonstrates how to get around this with a number of strategies. All
solutions take advantage of new `RUN --mount` Dockerfile
[syntax](https://docs.docker.com/engine/reference/builder/#run---mount) made
available by the [BuildKit backend](https://docs.docker.com/build/buildkit/).

## Strategies

An additional complexity is that `poetry-dynamic-versioning` only modifies the
version number in the code during the poetry build process, and reverts changes
once the command completes. Additionally, the `poetry install` installs the
package in editable mode, and this doesn't appear to be configurable. Therefore,
the `__version__` variable in the source code remains as the placeholder value.
There are a couple of approaches to handle this:

- Use poetry to build a wheel file, and install the wheel in the image using
  pip. The wheel reflects the dynamic version set by the tool. This strategy
  is implemented in the [`main`](https://github.com/Ogaday/demo-app/tree/main)
  branch.
- Use the `poetry-dynamic-versioning`
  [command](https://github.com/mtkennerly/poetry-dynamic-versioning#command-line-mode)
  in a docker build step to write the version to the source files. This command
  overwrites the `__version__` placeholder with the dynamic version. (This is
  also configurable) This strategy is implemented in the
  [`dynamic-version-script`](https://github.com/Ogaday/demo-app/tree/dynamic-version-script)
  branch.
- Look up the `__version__` using
  [`importlib.metadata`](https://docs.python.org/3/library/importlib.metadata.html#module-importlib.metadata).
  This strategy is implemented in the
  [`importlib-metadata`](https://github.com/Ogaday/demo-app/tree/importlib-metadata)
  branch.

There are different trade-offs to consider: For instance, packaging the code as a
wheel is the most steps, but might be easier to use in a multistage build.

## Requirements

- [`docker/dockerfile:1.2`](https://docs.docker.com/build/buildkit/dockerfile-frontend/)
  to enable the require BuildKit features.

## Running

The build process:

```bash
docker build -t demo-app .
```

Running the app container:

```bash
docker run --rm -it -p 5000:5000 demo-app
```

Checking the app version:

```bash
curl 127.0.0.1:5000
# {"__version__": "0.1.0"}
```
