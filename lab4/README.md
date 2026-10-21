# Lab 4

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 4 in this folder.

| Image | Base Image                | Size   | Rebuild Time |
|-------|---------------------------|--------|--------------|
| Naive | python:latest             | 1.15GB | 4.8s         |
| Slim  | python:3.12-slim-bookworm | 137MB  | 0.5s         |

- how much of the difference is the base image
> The slim image is 1.02GB smaller than the naive image

- whether the dependency layer is CACHED on a code-only rebuild and in which image
> On a code-only rebuild, the dependency installation layer was successfully CACHED in the Slim image because requirements.txt was copied and installed before app.py.

- what .dockerignore kept out of the context
> The .dockerignore file successfully kept out heavy, sensitive, and unnecessary files (such as .git, .github, __pycache__/, *.md, and local evidence/ directories) from entering the Docker build context.
