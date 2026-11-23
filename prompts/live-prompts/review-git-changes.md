---
name: review-git-changes
description: Review git/github changes
---
Spawn subagent(s) to review.
If available, copy the exact user request prompts to the review subagents.

# Skills to use if available
- gh-cli
- git-workflow-and-versioning
- code-review-and-quality
- other project related skills

# Review the git changes. Focus on:
- Bugs and logic errors
- Security issues
- Error and edge case handling gaps
- Potential regression issues
- Test coverage and redundancy (unit, integration, and end-to-end)
- Verbosity (i.e. are docs/comments concise and spot on)
- Efficiency (i.e. does the code solves the problems in the most simple and concise way)

# Review github status. Focus on:
- Report related issues (Open/Closed) to local changes and answer
    - Need change to issue status?
    - Need create sub-issues?
    - Need to add some comments?
        - if there are old comments, summarize them
- Briefly screen through open PRs and answer
    - Are these local changes related to certain prs?
        - if so, are there redundant local/remote changes?
