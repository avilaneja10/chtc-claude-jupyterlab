# chtc-claude-jupyterlab

One command from a cold laptop to a JupyterLab kernel and a Claude Code agent,
both running on a CHTC GPU node.

```
$ lab-local

  running on : mrudolphgpu4000.chtc.wisc.edu

  jupyter    : http://localhost:8747/lab?token=...
  claude     : https://claude.ai/code/...
```

Two browser tabs. Both execute on the GPU. Your work survives job restarts
without git gymnastics.

**Unofficial.** Not affiliated with or supported by CHTC. You are responsible
for what runs on shared hardware.

---

## Three machines

Every command below is labelled with where to run it. The distinction matters,
because these machines cannot see each other's filesystems or ports.

| Machine | What it is | How you get there |
|---|---|---|
| **Laptop** | Your own computer | — |
| **Access point** | `ap2001.chtc.wisc.edu`, shared login node. No compute allowed. | `ssh chtc` |
| **GPU node** | Where the job runs. No direct login. | `lab` puts you there |

```
laptop  --8747-->  access point  --8747-->  GPU node
                        |                       |
                        +------ /staging -------+
```

The tunnel chains twice, once per hop. The working directory lives on
`/staging`, which is mounted at the same path on the access point and the GPU
node, so files written by the job are already on the access point. Nothing to
transfer, nothing lost when a job ends.

Claude Code needs no port. Remote Control uses outbound-only HTTPS, so it
works from inside the job with no inbound connection.

---

## Before you start

- A **group-owned or prioritised GPU machine**. Not optional.
  `condor_ssh_to_job` was disabled on CHTC's shared GPU machines in April 2026,
  so the tunnel only works on hardware your group owns.
- Group staging space at `/staging/groups/<group>/`.
- An Apptainer container with JupyterLab and PyTorch.
- A paid Claude subscription. Console API keys are rejected by Remote Control.
- UW network or campus VPN.

**On the access point** — check you have a GPU machine you can use:

```bash
condor_status -constraint 'TotalGpus > 0' -af Machine GPUs_DeviceName
```

If nothing there belongs to your group, email chtc@cs.wisc.edu and ask whether
your account has prioritised GPU access before going further.

---

## Setup

### Step 1 — Clone and configure

**On the access point.**

```bash
ssh chtc
git clone https://github.com/avilaneja10/chtc-claude-jupyterlab.git ~/chtc-claude-jupyterlab
cd ~/chtc-claude-jupyterlab

mkdir -p ~/.chtc-jupyterlab
cp config.sh ~/.chtc-jupyterlab/config.sh
nano ~/.chtc-jupyterlab/config.sh
```

Set `NETID`, `STAGING_ROOT`, `GPU_MACHINE`, and `CONTAINER`.

Get real CPU and memory numbers from `condor_status` rather than guessing.
Over-requesting strands the whole node and blocks your labmates from the other
GPUs on it.

Pick unusual ports. `8888`, `8889`, and `8501` collide constantly on a shared
access point, and the failure looks like an unrelated bug.

### Step 2 — Install Claude Code onto staging

**On the access point.**

The native installer needs no Node.js, which matters because most JupyterLab
containers have no `npm`. Install it, then copy the binary to staging where the
job can reach it:

```bash
curl -fsSL https://claude.ai/install.sh | bash

mkdir -p /staging/groups/<group>/<netid>/tools/bin
cp ~/.local/bin/claude /staging/groups/<group>/<netid>/tools/bin/
```

### Step 3 — Run the installer

**On the access point.**

```bash
cd ~/chtc-claude-jupyterlab
./install.sh
```

This copies `lab` and `lab-stop` to `~/bin`, the job files to your project
directory, and `env.sh`, `config.sh`, `claude-login` to your staging tools
directory.

If it warns that `~/bin` is not on your PATH:

```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Step 4 — Put `lab-local` on your laptop

**On your laptop.** This is the only file that lives locally.

```bash
mkdir -p ~/bin
scp chtc:~/chtc-claude-jupyterlab/bin/lab-local ~/bin/
chmod +x ~/bin/lab-local
```

### Step 5 — Add the SSH alias

**On your laptop**, in `~/.ssh/config`:

```
Host chtc
    HostName ap2001.chtc.wisc.edu
    User YOUR_NETID
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 4h
    ServerAliveInterval 60
```

`ControlPersist` reuses one authenticated connection, so `lab-local` stops
triggering a DUO push on every run.

Verify:

```bash
ssh chtc echo ok
```

### Step 6 — First run and login

**On your laptop:**

```bash
lab-local
```

It will report `NOT AUTHENTICATED` and drop you into a shell on the GPU node.

**In that GPU shell**, run the `claude-login` path it printed. Then:

1. Type `/login`
2. Open the printed URL on your laptop
3. Authorize with your claude.ai account, not a Console API key
4. Paste the code back
5. Accept the workspace trust prompt
6. `exit`

**On the access point** (you are already there after exiting the GPU shell):

```bash
lab-stop
lab
```

Both URLs should now print. If credentials landed in your staging
`claude-config` directory, this login is a once-ever step.

### Step 7 — Optional: fence your agent

**On the access point.** Copy `examples/CLAUDE.md` to the root of whatever
project you work on. It tells the agent not to run compute on the access
point, which is shared login hardware. Inside the job it can run freely,
because those resources are already allocated to you.

---

## Daily use

| Command | Run on | What it does |
|---|---|---|
| `lab-local` | laptop | Cold start to a working session |
| `lab` | access point | Same, when already logged in |
| `lab-stop` | access point | Release the GPU |

Exiting the GPU shell detaches without killing the session. The job keeps
running, so you can close your laptop and reattach with the same command.

Run `lab-stop` when you finish for the day. On group-owned hardware, an idle
GPU is your labmates' idle GPU.

---

## Things that cost a day to find out

**`+GPUJobLength = "short"` silently caps your job at 12 hours.** That and
`+WantGPULab = true` are GPU Lab attributes and do not belong on a group
machine. If a session dies twice a day for no visible reason, this is why. Both
are omitted here, so the standard 72 hour hold applies instead.

**A `sleep` job holding a GPU is the pattern CHTC removed shared-GPU ssh access
over.** Make the session the job. Here the executable is Jupyter itself, so the
GPU frees itself when you are done.

**`nvidia-smi` missing does not mean the GPU is missing.** It is a userspace
tool many containers omit. Check `torch.cuda.get_device_name(0)` instead.

**`lsof` shows nothing while `bind` still fails.** On a shared machine `lsof -i`
only reports your own processes. Use `ss -lnt` to see sockets owned by others.

**Scripts run under `sh`, not `bash`.** An HTCondor executable does not get your
login shell. `set -o pipefail` fails, and nothing from `.bashrc` is loaded,
which is why PATH must be set explicitly.

**`claude remote-control` asks `Enable Remote Control? (y/n)` on startup.**
Backgrounded from a job there is no stdin to answer it, so it blocks forever
with no error. There is no `--yes` flag as of v2.1.x. Pipe in a `y`.

**Workspace trust is per-directory and never saved for `$HOME`.** Run `claude`
once in the actual working directory.

---

## License

MIT.
