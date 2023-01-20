# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.10

FROM python:${PYTHON_VERSION}

# Define build dependency versions:
ARG TINI_VERSION=v0.19.0
ARG PIP_VERSION=22.3.1
ARG POETRY_VERSION=1.3.2

# Use tini as an init process.
ADD https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini /tini
RUN chmod +x /tini

RUN pip install -U "pip==${PIP_VERSION}" && \
    pip install -U "poetry==${POETRY_VERSION}"

WORKDIR /demo-app

# First install build tools and app dependencies for better caching.
COPY pyproject.toml poetry.lock README.md .
RUN poetry config virtualenvs.create false && \
    poetry install --no-root && \
    poetry self add poetry-dynamic-versioning
    # Add dynamic-versioning after dependencies install so we don't need to
    # mount the .git directory in this stage.

# Then install the app and run the poetry-dynamic-versioning script to overwrite
# the __version__ variable in the package code. See:
# https://github.com/mtkennerly/poetry-dynamic-versioning#command-line-mode
COPY demo_app/ demo_app/
RUN --mount=source=.git,target=/demo-app/.git \
    poetry install --only-root && \
    poetry dynamic-versioning

ENV FLASK_APP=demo_app.app

# Change workdir as we have already installed our app and no longer need the
# source code.
WORKDIR /

ENTRYPOINT ["/tini", "--"]

EXPOSE 5000

CMD ["flask", "run", "--host", "0.0.0.0"]
