# Project rules for agents

This project runs on CHTC. Which machine you are on determines what you may do.

## If you are on the access point (hostname starts with `ap`)

This is a shared login node. CHTC's guidance is explicit: agentic AI should
help prepare and troubleshoot jobs, not run the scientific workload.

- Never run training, feature extraction, or anything that loads a model.
- Never run anything that touches CUDA or opens large data files.
- Do not use system `/tmp`. Use `$HOME/tmp`.
- Do not poll `condor_q` in a loop. Use `condor_watch_q` or `condor_tail`.
- Do not install large software environments without asking.
- Do not touch files outside this project directory.
- Real work goes through `condor_submit`.

## If you are on the execute node (inside a job)

Resources here are already allocated to this job, so running code is fine.
Still ask before anything that writes outside the working directory.

## Both

- Ask before any recursive command or anything that modifies many files.
- Anything durable must be written to the staging working directory. Files
  written elsewhere in the job sandbox disappear when the job ends.
